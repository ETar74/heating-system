// control.cpp — Оркестратор системы управления (Fail-Safe)
// Связывает control_logic (решения) и control_io (исполнение)

#include "control.h"
#include "control_io.h"
#include "sensors.h"
#include "storage.h"
#include "timekeeper.h"

Control control;

void Control::begin() {
    controlIO.begin();

    storage.loadSettings(settings);
    storage.loadDeviceStates(states.boiler, states.floor_pump,
                             states.radiator_pump, states.elec_boiler);

    // FAIL-SAFE: При старте все реле ВЫКЛ, пока не пройдёт первая оценка
    states.boiler = states.floor_pump = states.radiator_pump = states.elec_boiler = false;

    memcpy(&previousStates, &states, sizeof(DeviceStates));
    clearAllManualOverrides();

    eqHead = eqTail = eqCount = 0;
    eventIdCounter = 1;
    lastControlTime = 0;
    lastStatusPrint = 0;
    lastPhaseCheck = 0;

    Serial.println("[Control] Initialized (Orchestrator Fail-Safe mode)");
    controlIO.printRelayStatus();
}

void Control::update() {
    if (millis() - lastControlTime < CONTROL_INTERVAL) return;
    lastControlTime = millis();

    checkManualOverrides();
    checkPhases();
    evaluateAllRelays();
    generateStateChangeEvents();

    controlIO.saveDeviceStates(states);

    if (millis() - lastStatusPrint > 10000) {
        lastStatusPrint = millis();
        controlIO.printRelayStatus();
    }
}

void Control::evaluateAllRelays() {
    SensorData sd = sensors.getData();
    PhaseStatus statusPhases;
    statusPhases.l1 = phaseL1;
    statusPhases.l2 = phaseL2;
    statusPhases.l3 = phaseL3;

    DateTime dt = timekeeper.getDateTime();
    uint8_t nowH = dt.hour;
    uint8_t nowM = dt.minute;
    bool timeSynced = timekeeper.isSynced();

    // ===== DIAGNOSTIC: Trace Sch flag path =====
    for (uint8_t i = 0; i < DEVICE_COUNT; i++) {
        const auto& sched = settings.schedule[i];
        for (uint8_t s = 0; s < SCHEDULE_SLOTS_PER_DEVICE; s++) {
            const auto& sl = sched.slots[s];
            //Serial.printf(" %d[en=%d %02d:%02d-%02d:%02d]", s, sl.enabled, sl.startH, sl.startM, sl.endH, sl.endM);
        }
        // Test isScheduleActive directly
        bool schOk = isScheduleActive(i, settings, nowH, nowM);
    }
    // ===== END DIAGNOSTIC =====

    RelayDecision decisions[DEVICE_COUNT];
    ::evaluateAllRelays(sd, statusPhases, settings, states, decisions, nowH, nowM);

    for (uint8_t i = 0; i < DEVICE_COUNT; i++) {
        DeviceId dev = static_cast<DeviceId>(i);
        bool newState = decisions[i].desiredState;

        controlIO.applyRelayDecision(dev, decisions[i]);
        setDeviceState(i, newState);
    }
}
void Control::checkManualOverrides() {
    uint8_t devices[4] = { DEV_BOILER, DEV_ELEC_BOILER, DEV_FLOOR_PUMP, DEV_RADIATOR_PUMP };
    for (int i = 0; i < 4; i++) {
        ManualOverride* mo = getMO(devices[i]);
        if (mo && mo->active && millis() >= mo->expiresAt) {
            mo->active = false;
            setDeviceState(devices[i], mo->savedAutoState);
            char msg[64];
            snprintf(msg, sizeof(msg), "Manual timeout on dev %d -> AUTO", devices[i]);
            addEvent("INFO", msg);
            Serial.printf("[Control] Device %d: Manual timeout -> AUTO\n", devices[i]);
        }
    }
}

void Control::checkPhases() {
    if (millis() - lastPhaseCheck < 1000) return;
    lastPhaseCheck = millis();

    // Read with averaging (done inside readPhases)
    bool l1, l2, l3;
    controlIO.readPhases(l1, l2, l3);

    // If same as current confirmed — reset debounce
    if (l1 == phaseL1 && l2 == phaseL2 && l3 == phaseL3) {
        phaseDebounce = 0;
        return;
    }

    // Debounce: track pending state
    if (l1 == pendL1 && l2 == pendL2 && l3 == pendL3) {
        phaseDebounce++;
    } else {
        pendL1 = l1; pendL2 = l2; pendL3 = l3;
        phaseDebounce = 1;
    }

    // Confirm after 3 consecutive readings
    if (phaseDebounce >= 3) {
        phaseL1 = l1; phaseL2 = l2; phaseL3 = l3;
        phaseDebounce = 0;

        char msg[64];
        if (!phaseL1 && !phaseL2 && !phaseL3) {
            snprintf(msg, sizeof(msg), "ALL phases LOST");
            addEvent("ALARM", msg);
        } else if (phaseL1 && phaseL2 && phaseL3) {
            snprintf(msg, sizeof(msg), "All phases OK");
            addEvent("INFO", msg);
        } else {
            snprintf(msg, sizeof(msg), "Phase loss: %s%s%s",
                     !phaseL1 ? "L1 " : "", !phaseL2 ? "L2 " : "", !phaseL3 ? "L3 " : "");
            addEvent("ERROR", msg);
        }
        Serial.printf("[Control] %s\n", msg);
    }
}

bool Control::phasesOk() { return phaseL1 && phaseL2 && phaseL3; }

void Control::generateStateChangeEvents() {
    if (previousStates.boiler        != states.boiler)        addEvent("INFO", states.boiler        ? "Boiler ON"        : "Boiler OFF");
    if (previousStates.elec_boiler   != states.elec_boiler)   addEvent("INFO", states.elec_boiler   ? "ElecBoiler ON"   : "ElecBoiler OFF");
    if (previousStates.floor_pump    != states.floor_pump)    addEvent("INFO", states.floor_pump    ? "FloorPump ON"    : "FloorPump OFF");
    if (previousStates.radiator_pump != states.radiator_pump) addEvent("INFO", states.radiator_pump ? "RadiatorPump ON" : "RadiatorPump OFF");
    memcpy(&previousStates, &states, sizeof(DeviceStates));
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
bool Control::isInSchedule(uint8_t device) {
    DateTime dt = timekeeper.getDateTime();
    return isScheduleActive(device, settings, dt.hour, dt.minute);
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

// ===== РАСПИСАНИЕ (API) =====
void Control::adjustSchedule(uint8_t device, uint8_t slot, uint8_t field, int8_t dir) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    TimeSlot &s = settings.schedule[device].slots[slot];
    switch (field) {
        case 0: s.startH = (s.startH + dir + 24) % 24; break;
        case 1: s.startM = (s.startM + dir + 60) % 60; break;
        case 2: s.endH   = (s.endH + dir + 24) % 24; break;
        case 3: s.endM   = (s.endM + dir + 60) % 60; break;
    }
}

void Control::toggleScheduleEnabled(uint8_t device) {
    if (device >= DEVICE_COUNT) return;
    settings.schedule[device].enabled = !settings.schedule[device].enabled;
}

void Control::toggleSlotEnabled(uint8_t device, uint8_t slot) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    settings.schedule[device].slots[slot].enabled = !settings.schedule[device].slots[slot].enabled;
}

void Control::clearSlot(uint8_t device, uint8_t slot) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    settings.schedule[device].slots[slot] = TimeSlot();
}

void Control::setSlotTime(uint8_t device, uint8_t slot, uint8_t startH, uint8_t startM, uint8_t endH, uint8_t endM) {
    if (device >= DEVICE_COUNT || slot >= SCHEDULE_SLOTS_PER_DEVICE) return;
    TimeSlot &s = settings.schedule[device].slots[slot];
    s.startH = startH; s.startM = startM;
    s.endH = endH;   s.endM = endM;
    s.enabled = true;
}

// ===== PUBLIC API (Nextion / Server) =====
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
        case DEV_BOILER:        states.boiler = state; controlIO.setBoiler(state); break;
        case DEV_ELEC_BOILER:   states.elec_boiler = state; controlIO.setElecBoiler(state); break;
        case DEV_FLOOR_PUMP:    states.floor_pump = state; controlIO.setFloorPump(state); break;
        case DEV_RADIATOR_PUMP: states.radiator_pump = state; controlIO.setRadiatorPump(state); break;
    }
}
