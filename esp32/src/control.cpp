#include "control.h"
#include "sensors.h"
#include "storage.h"
#include "timekeeper.h"

Control control;

void Control::begin() {
    pinMode(PIN_RELAY_BOILER, OUTPUT);
    pinMode(PIN_RELAY_FLOOR, OUTPUT);
    pinMode(PIN_RELAY_RADIATOR, OUTPUT);
    pinMode(PIN_RELAY_ELEC, OUTPUT);
    pinMode(PIN_PHASE_SENSOR, INPUT);
    pinMode(PIN_BUTTON_CALIB, INPUT_PULLUP);

    storage.loadSettings(settings);
    storage.loadDeviceStates(states.boiler, states.floor_pump,
                             states.radiator_pump, states.elec_boiler);

    digitalWrite(PIN_RELAY_BOILER, states.boiler);
    digitalWrite(PIN_RELAY_FLOOR, states.floor_pump);
    digitalWrite(PIN_RELAY_RADIATOR, states.radiator_pump);
    digitalWrite(PIN_RELAY_ELEC, states.elec_boiler);

    memcpy(&previousStates, &states, sizeof(DeviceStates));
    clearAllManualOverrides();

    eqHead = eqTail = eqCount = 0;
    eventIdCounter = 1;
    lastControlTime = 0;
    lastStatusPrint = 0;

    Serial.println("[Control] Initialized");
    printRelayStatus();
}

// ===== Вспомогательные методы доступа к устройствам =====
ManualOverride* Control::getMO(uint8_t device) {
    switch (device) {
        case DEV_BOILER:        return &states.boiler_mo;
        case DEV_ELEC_BOILER:   return &states.elec_boiler_mo;
        case DEV_FLOOR_PUMP:    return &states.floor_pump_mo;
        case DEV_RADIATOR_PUMP: return &states.radiator_pump_mo;
        default:                return nullptr;
    }
}

bool Control::getDeviceState(uint8_t device) {
    switch (device) {
        case DEV_BOILER:        return states.boiler;
        case DEV_ELEC_BOILER:   return states.elec_boiler;
        case DEV_FLOOR_PUMP:    return states.floor_pump;
        case DEV_RADIATOR_PUMP: return states.radiator_pump;
        default:                return false;
    }
}

void Control::setDeviceState(uint8_t device, bool state) {
    switch (device) {
        case DEV_BOILER:        setBoiler(state); break;
        case DEV_ELEC_BOILER:   setElecBoiler(state); break;
        case DEV_FLOOR_PUMP:    setFloorPump(state); break;
        case DEV_RADIATOR_PUMP: setRadiatorPump(state); break;
    }
}

bool Control::isManualActive(uint8_t device) {
    ManualOverride* mo = getMO(device);
    return mo ? mo->active : false;
}

unsigned long Control::getManualRemaining(uint8_t device) {
    ManualOverride* mo = getMO(device);
    if (!mo || !mo->active) return 0;
    unsigned long now = millis();
    if (now >= mo->expiresAt) return 0;
    return (mo->expiresAt - now) / 1000;
}

// ===== Главный цикл управления =====
void Control::update() {
    if (millis() - lastControlTime < CONTROL_INTERVAL) return;
    lastControlTime = millis();

    checkManualOverrides();
    memcpy(&previousStates, &states, sizeof(DeviceStates));

    controlBoiler();
    controlElecBoiler();
    controlFloorPump();
    controlRadiatorPump();
    checkCriticalConditions();
    checkPhases();
    generateStateChangeEvents();

    storage.saveDeviceStates(states.boiler, states.floor_pump,
                             states.radiator_pump, states.elec_boiler);

    if (millis() - lastStatusPrint > 10000) {
        lastStatusPrint = millis();
        printRelayStatus();
    }
}

void Control::updateRelay(uint8_t pin, bool &currentState, bool newState, const char* name) {
    if (currentState != newState) {
        currentState = newState;
        digitalWrite(pin, newState);
        Serial.printf("[Control] %s: %s\n", name, newState ? "ON" : "OFF");
    }
}

void Control::setBoiler(bool state)       { updateRelay(PIN_RELAY_BOILER,   states.boiler,        state, "Boiler"); }
void Control::setElecBoiler(bool state)   { updateRelay(PIN_RELAY_ELEC,     states.elec_boiler,   state, "ElecBoiler"); }
void Control::setFloorPump(bool state)    { updateRelay(PIN_RELAY_FLOOR,    states.floor_pump,    state, "FloorPump"); }
void Control::setRadiatorPump(bool state) { updateRelay(PIN_RELAY_RADIATOR, states.radiator_pump, state, "RadiatorPump"); }

// ===== Расписание =====
bool Control::isInSchedule(uint8_t device) {
    if (device >= DEVICE_COUNT) return false;
    DeviceSchedule &sched = settings.schedule[device];
    
    // Проверяем каждый интервал
    DateTime now = timekeeper.getDateTime();
    uint16_t currentMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < SCHEDULE_SLOTS_PER_DEVICE; i++) {
        TimeSlot &slot = sched.slots[i];
        if (!slot.enabled) continue;  // ← только включённые интервалы
        
        // Если время не задано — пропускаем
        if (slot.startH == 0 && slot.startM == 0 && slot.endH == 0 && slot.endM == 0) continue;

        uint16_t startMinutes = slot.startH * 60 + slot.startM;
        uint16_t endMinutes   = slot.endH   * 60 + slot.endM;

        if (startMinutes < endMinutes) {
            if (currentMinutes >= startMinutes && currentMinutes < endMinutes) return true;
        } else {
            // Переход через полночь
            if (currentMinutes >= startMinutes || currentMinutes < endMinutes) return true;
        }
    }
    return false;  // Ни один интервал не активен
}

void Control::adjustSchedule(uint8_t device, uint8_t slot, uint8_t field, int8_t dir) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    TimeSlot &s = settings.schedule[device].slots[slot];
    switch (field) {
        case 0: s.startH = (uint8_t)constrain((int)s.startH + dir, 0, 23); break;
        case 1: s.startM = (uint8_t)constrain((int)s.startM + dir, 0, 59); break;
        case 2: s.endH   = (uint8_t)constrain((int)s.endH   + dir, 0, 23); break;
        case 3: s.endM   = (uint8_t)constrain((int)s.endM   + dir, 0, 59); break;
    }
}

void Control::toggleScheduleEnabled(uint8_t device) {
    if (device >= DEVICE_COUNT) return;
    settings.schedule[device].enabled = !settings.schedule[device].enabled;
    Serial.printf("[Control] Schedule device %d: %s\n", device, settings.schedule[device].enabled ? "ENABLED" : "DISABLED");
}

void Control::toggleSlotEnabled(uint8_t device, uint8_t slot) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    TimeSlot &s = settings.schedule[device].slots[slot];
    // Нельзя включить пустой интервал
    if (!s.enabled && s.startH == 0 && s.startM == 0 && s.endH == 0 && s.endM == 0) {
        Serial.printf("[Control] Cannot enable empty slot %d on device %d\n", slot, device);
        return;
    }
    s.enabled = !s.enabled;
    Serial.printf("[Control] Slot %d device %d: %s\n", slot, device, s.enabled ? "ENABLED" : "DISABLED");
}

void Control::clearSlot(uint8_t device, uint8_t slot) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    TimeSlot &s = settings.schedule[device].slots[slot];
    s.startH = 0; s.startM = 0;
    s.endH = 0;   s.endM = 0;
    s.enabled = false;
    Serial.printf("[Control] Slot %d cleared for device %d\n", slot, device);
}

void Control::setSlotTime(uint8_t device, uint8_t slot, uint8_t startH, uint8_t startM, uint8_t endH, uint8_t endM) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    TimeSlot &s = settings.schedule[device].slots[slot];
    s.startH = startH; s.startM = startM;
    s.endH = endH;     s.endM = endM;
    // Авто-enable при вводе времени
    s.enabled = true;
    Serial.printf("[Control] Slot %d device %d set: %02d:%02d-%02d:%02d (auto-enabled)\n",
                  slot, device, startH, startM, endH, endM);
}

void Control::printRelayStatus() {
    Serial.printf("[Status] Relays -> Boiler:%s Elec:%s Floor:%s Rad:%s\n",
        states.boiler        ? "ON " : "OFF",
        states.elec_boiler   ? "ON " : "OFF",
        states.floor_pump    ? "ON " : "OFF",
        states.radiator_pump ? "ON " : "OFF");

    // Диагностика фаз: сырое значение ADC с GPIO 34 + расшифровка
    int adc = analogRead(PIN_PHASE_SENSOR);
    Serial.printf("[Status] Phase ADC(GPIO34)=%d  L1:%s L2:%s L3:%s\n",
        adc,
        phaseL1 ? "OK" : "LOST",
        phaseL2 ? "OK" : "LOST",
        phaseL3 ? "OK" : "LOST");
}

// ===== Истечение ручного управления: ВОЗВРАТ к АВТО =====
void Control::checkManualOverrides() {
    unsigned long now = millis();

    uint8_t devices[4] = { DEV_BOILER, DEV_ELEC_BOILER, DEV_FLOOR_PUMP, DEV_RADIATOR_PUMP };
    const char* names[4] = { "Boiler", "ElecBoiler", "FloorPump", "RadiatorPump" };

    for (int i = 0; i < 4; i++) {
        ManualOverride* mo = getMO(devices[i]);
        if (!mo || !mo->active) continue;

        if (now >= mo->expiresAt) {
            mo->active = false;
            setDeviceState(devices[i], mo->savedAutoState);
            Serial.printf("[Control] %s: manual EXPIRED -> returned to AUTO (state=%d)\n",
                          names[i], mo->savedAutoState);
            addEvent("INFO", "Manual override expired, returned to AUTO");
        }
    }
}

// ===== Алгоритмы автоматики (включительные сравнения >= / <=) =====

void Control::controlBoiler() {
    // Ручной режим работает всегда
    if (states.boiler_mo.active) { 
        setBoiler(states.boiler_mo.forcedState); 
        return; 
    }
    
    // УСЛОВИЕ 1: Проверяем расписание
    if (!isInSchedule(DEV_BOILER)) {
        // Нет активного интервала → устройство выключено
        setBoiler(false);
        return;
    }
    
    // УСЛОВИЕ 2: Проверяем температуру
    if (!sensors.isSensorValid(ROLE_BOILER)) { 
        setBoiler(false); 
        return; 
    }
    
    float t = sensors.getTemperature(ROLE_BOILER);
    if (t >= settings.boiler_threshold_on) {
        setBoiler(true);   // Температура требует включения
    } else if (t <= settings.boiler_threshold_off) {
        setBoiler(false);  // Температура требует выключения
    }
    // В зоне между порогами — не меняем состояние
}

void Control::controlElecBoiler() {
    if (states.elec_boiler_mo.active) { 
        setElecBoiler(states.elec_boiler_mo.forcedState); 
        return; 
    }
    
    // УСЛОВИЕ 1: Расписание
    if (!isInSchedule(DEV_ELEC_BOILER)) {
        setElecBoiler(false);
        return;
    }
    
    // УСЛОВИЕ 2: Температура
    if (!sensors.isSensorValid(ROLE_ACCUMULATOR)) { 
        setElecBoiler(false); 
        return; 
    }
    
    float t = sensors.getTemperature(ROLE_ACCUMULATOR);
    if (t >= settings.TA_target_off) {
        setElecBoiler(false);
    } else if (t <= settings.TA_target_on) {
        setElecBoiler(true);
    }
}

void Control::controlFloorPump() {
    if (states.floor_pump_mo.active) { 
        setFloorPump(states.floor_pump_mo.forcedState); 
        return; 
    }
    
    // УСЛОВИЕ 1: Расписание
    if (!isInSchedule(DEV_FLOOR_PUMP)) {
        setFloorPump(false);
        return;
    }
    
    // УСЛОВИЕ 2: Температура
    if (!sensors.isSensorValid(ROLE_FLOOR)) { 
        setFloorPump(false); 
        return; 
    }
    
    float floorT = sensors.getTemperature(ROLE_FLOOR);
    
    // Проверяем, есть ли тепло в ТА
    bool taHasHeat = false;
    if (sensors.isSensorValid(ROLE_ACCUMULATOR)) {
        float taT = sensors.getTemperature(ROLE_ACCUMULATOR);
        taHasHeat = (taT > FLOW_HOT_TA_MIN);
    }
    
    if (floorT >= settings.floor_threshold_off) {
        setFloorPump(false);
    } else if (!taHasHeat) {
        setFloorPump(false);  // В ТА нет тепла
    } else if (floorT <= settings.floor_threshold_on) {
        setFloorPump(true);
    }
}

void Control::controlRadiatorPump() {
    if (states.radiator_pump_mo.active) { 
        setRadiatorPump(states.radiator_pump_mo.forcedState); 
        return; 
    }
    
    // УСЛОВИЕ 1: Расписание
    if (!isInSchedule(DEV_RADIATOR_PUMP)) {
        setRadiatorPump(false);
        return;
    }
    
    // УСЛОВИЕ 2: Температура
    if (!sensors.isSensorValid(ROLE_ROOM)) { 
        setRadiatorPump(false); 
        return; 
    }
    
    float t = sensors.getTemperature(ROLE_ROOM);
    if (t >= settings.room_target_off) {
        setRadiatorPump(false);
    } else if (t <= settings.room_target_on) {
        setRadiatorPump(true);
    }
}

void Control::checkCriticalConditions() {
    if (sensors.isSensorValid(ROLE_BOILER)) {
        float boilerT = sensors.getTemperature(ROLE_BOILER);
        if (boilerT > CRITICAL_BOILER_TEMP_MAX) {
            char msg[64];
            snprintf(msg, sizeof(msg), "CRITICAL: Boiler temp %.1fC", boilerT);
            addEvent("ALARM", msg);
            setBoiler(false);
            setElecBoiler(false);
        }
    }
    if (sensors.isSensorValid(ROLE_ACCUMULATOR)) {
        float accT = sensors.getTemperature(ROLE_ACCUMULATOR);
        if (accT > CRITICAL_ACCUMULATOR_TEMP_MAX) {
            char msg[64];
            snprintf(msg, sizeof(msg), "CRITICAL: Accumulator temp %.1fC", accT);
            addEvent("ALARM", msg);
            setElecBoiler(false);
        }
    }
}

// ===== НОВОЕ: декодер фаз по калибровочной таблице =====
// Измеренные диапазоны ADC (GPIO34):
//   0–1472    L1=1 L2=1 L3=1   все фазы
//   1425–1616 L1=0 L2=1 L3=1   нет L1
//   1624–1800 L1=1 L2=1 L3=0   нет L3
//   1801–2080 L1=0 L2=1 L3=0   нет L1+L3
//   2081–2450 L1=1 L2=0 L3=1   нет L2
//   2451–2940 L1=0 L2=0 L3=1   нет L1+L2
//   2941–3668 L1=1 L2=0 L3=0   нет L2+L3
//   3800–4095 L1=0 L2=0 L3=0   нет всех
// Границы между диапазонами взяты по серединам перекрытий/зазоров.
void Control::decodePhases(int adc, bool &l1, bool &l2, bool &l3) {
        if (adc < 500) {
        l1 = false;
        l2 = false;
        l3 = false;
        return;
    }

    if      (adc <= 1448) { l1 = true;  l2 = true;  l3 = true;  }
    else if (adc <= 1620) { l1 = false; l2 = true;  l3 = true;  }
    else if (adc <= 1800) { l1 = true;  l2 = true;  l3 = false; }
    else if (adc <= 2080) { l1 = false; l2 = true;  l3 = false; }
    else if (adc <= 2450) { l1 = true;  l2 = false; l3 = true;  }
    else if (adc <= 2940) { l1 = false; l2 = false; l3 = true;  }
    else if (adc <= 3733) { l1 = true;  l2 = false; l3 = false; }
    else                  { l1 = false; l2 = false; l3 = false; }
}

// ===== НОВОЕ: опрос фаз с усреднением и дебаунсом =====
void Control::checkPhases() {
    // Усреднение 8 замеров ADC — защита от помех
    long sum = 0;
    for (int i = 0; i < 8; i++) {
        sum += analogRead(PIN_PHASE_SENSOR);
        delay(2);
    }
    int adc = (int)(sum / 8);

    bool l1, l2, l3;
    decodePhases(adc, l1, l2, l3);

    // Если совпадает с текущим — сброс дебаунса
    if (l1 == phaseL1 && l2 == phaseL2 && l3 == phaseL3) {
        phaseDebounce = 0;
        return;
    }

    // Дебаунс: подтверждаем новое состояние 3 одинаковых замера подряд
    if (l1 == pendL1 && l2 == pendL2 && l3 == pendL3) {
        phaseDebounce++;
    } else {
        pendL1 = l1; pendL2 = l2; pendL3 = l3;
        phaseDebounce = 1;
    }

    if (phaseDebounce >= 3) {
        phaseL1 = l1; phaseL2 = l2; phaseL3 = l3;
        phaseDebounce = 0;

        char msg[64];
        if (!phaseL1 && !phaseL2 && !phaseL3) {
            snprintf(msg, sizeof(msg), "ALL phases LOST (ADC=%d)", adc);
            addEvent("ALARM", msg);
        } else if (phaseL1 && phaseL2 && phaseL3) {
            snprintf(msg, sizeof(msg), "All phases OK (ADC=%d)", adc);
            addEvent("INFO", msg);
        } else {
            snprintf(msg, sizeof(msg), "Phase loss: %s%s%s(ADC=%d)",
                     !phaseL1 ? "L1 " : "", !phaseL2 ? "L2 " : "", !phaseL3 ? "L3 " : "", adc);
            addEvent("ERROR", msg);
        }
        Serial.printf("[Control] %s\n", msg);
    }
}

bool Control::phasesOk() { return phaseL1 && phaseL2 && phaseL3; }
bool Control::isNightMode() { return false; }

void Control::generateStateChangeEvents() {
    if (previousStates.boiler        != states.boiler)        addEvent("INFO", states.boiler        ? "Boiler ON"        : "Boiler OFF");
    if (previousStates.elec_boiler   != states.elec_boiler)   addEvent("INFO", states.elec_boiler   ? "ElecBoiler ON"   : "ElecBoiler OFF");
    if (previousStates.floor_pump    != states.floor_pump)    addEvent("INFO", states.floor_pump    ? "FloorPump ON"    : "FloorPump OFF");
    if (previousStates.radiator_pump != states.radiator_pump) addEvent("INFO", states.radiator_pump ? "RadiatorPump ON" : "RadiatorPump OFF");
}

void Control::addEvent(const char* type, const char* message) {
    if (eqCount >= MAX_EVENTS) { eqHead = (eqHead + 1) % MAX_EVENTS; eqCount--; }
    DeviceEvent &e = eventQueue[eqTail];
    e.id = eventIdCounter++;
    e.timestamp = millis() / 1000;
    e.type = type;
    e.message = message;
    eqTail = (eqTail + 1) % MAX_EVENTS;
    eqCount++;
    Serial.printf("[Control] Event [%s] %s\n", type, message);
}

bool Control::hasPendingEvents() { return eqCount > 0; }

DeviceEvent Control::getNextEvent() {
    if (eqCount == 0) return {0, 0, "", ""};
    DeviceEvent e = eventQueue[eqHead];
    eqHead = (eqHead + 1) % MAX_EVENTS;
    eqCount--;
    return e;
}

int Control::getEventCount() { return eqCount; }
DeviceStates Control::getStates() { return states; }

// ===== Установка ручного управления =====
void Control::setManualOverride(uint8_t device, bool state) {
    ManualOverride* mo = getMO(device);
    if (!mo) return;

    if (!mo->active) {
        mo->savedAutoState = getDeviceState(device);
    }
    mo->active = true;
    mo->forcedState = state;
    mo->expiresAt = millis() + ((unsigned long)settings.manual_timeout * 1000UL);

    setDeviceState(device, state);

    Serial.printf("[Control] Manual override: device=%d forced=%d timeout=%d sec (savedAuto=%d)\n",
                  device, state, settings.manual_timeout, mo->savedAutoState);
}

void Control::clearAllManualOverrides() {
    uint8_t devices[4] = { DEV_BOILER, DEV_ELEC_BOILER, DEV_FLOOR_PUMP, DEV_RADIATOR_PUMP };
    for (int i = 0; i < 4; i++) {
        ManualOverride* mo = getMO(devices[i]);
        if (!mo) continue;
        if (mo->active) {
            mo->active = false;
            setDeviceState(devices[i], mo->savedAutoState);
            Serial.printf("[Control] Device %d: manual cleared -> AUTO\n", devices[i]);
        }
    }
}

void Control::emergencyStop() {
    unsigned long expiresAt = millis() + 300000;  // 5 минут

    uint8_t devices[4] = { DEV_BOILER, DEV_ELEC_BOILER, DEV_FLOOR_PUMP, DEV_RADIATOR_PUMP };
    for (int i = 0; i < 4; i++) {
        ManualOverride* mo = getMO(devices[i]);
        if (!mo) continue;
        mo->savedAutoState = getDeviceState(devices[i]);
        mo->active = true;
        mo->forcedState = false;
        mo->expiresAt = expiresAt;
        setDeviceState(devices[i], false);
    }

    addEvent("ALARM", "EMERGENCY STOP activated");
    Serial.println("[Control] EMERGENCY STOP - all devices OFF for 5 min");
}