#include "sensors.h"
#include "storage.h"

Sensors sensors;

void Sensors::begin() {
    dallas.begin();
    dallas.setResolution(12);

    if (dallas.getDeviceCount() == 0) {
        Serial.println("[Sensors] No sensors on first scan, retry...");
        delay(500);
        dallas.begin();
    }

    calibrating = false;
    discoveredCount = 0;

    data.room = data.boiler = data.floor = data.accumulator = data.outdoor = 0;
    data.room_valid = data.boiler_valid = data.floor_valid =
    data.accumulator_valid = data.outdoor_valid = false;
    data.lastUpdate = 0;

    loadAddresses();
    scanBus();

    Serial.printf("[Sensors] Found %d sensors on bus\n", dallas.getDeviceCount());
}

DeviceAddress* Sensors::roleAddr(uint8_t role) {
    switch (role) {
        case ROLE_ROOM:        return &addresses.room;
        case ROLE_BOILER:      return &addresses.boiler;
        case ROLE_FLOOR:       return &addresses.floor;
        case ROLE_ACCUMULATOR: return &addresses.accumulator;
        case ROLE_OUTDOOR:     return &addresses.outdoor;
        default:               return nullptr;
    }
}

bool Sensors::isZeroAddress(const DeviceAddress &addr) {
    for (uint8_t i = 0; i < 8; i++) if (addr[i] != 0x00) return false;
    return true;
}

bool Sensors::isOnBus(const DeviceAddress &addr) {
    int count = dallas.getDeviceCount();
    for (int i = 0; i < count; i++) {
        DeviceAddress found;
        if (dallas.getAddress(found, i) && memcmp(found, addr, 8) == 0) return true;
    }
    return false;
}

void Sensors::loadAddresses() {
    const char* names[SENSOR_COUNT] = { "Room", "Boiler", "Floor", "Accumulator", "Outdoor" };
    addresses.calibrated = true;

    for (int role = 0; role < SENSOR_COUNT; role++) {
        DeviceAddress* a = roleAddr(role);
        if (!storage.loadSensorAddress(role, *a)) {
            memset(a, 0, 8);
            addresses.calibrated = false;
        }
    }

    for (int role = 0; role < SENSOR_COUNT; role++) {
        DeviceAddress* a = roleAddr(role);
        if (!isZeroAddress(*a) && !isOnBus(*a)) {
            Serial.printf("[Sensors] Role %d (%s): not on bus -> disabled\n", role, names[role]);
            memset(a, 0, 8);
        }
    }

    for (int i = 0; i < SENSOR_COUNT; i++) {
        DeviceAddress* ai = roleAddr(i);
        if (isZeroAddress(*ai)) continue;
        for (int j = 0; j < i; j++) {
            if (memcmp(ai, roleAddr(j), 8) == 0) {
                Serial.printf("[Sensors] Role %d (%s): DUPLICATE of role %d -> disabled\n", i, names[i], j);
                memset(ai, 0, 8);
            }
        }
    }

    int busCount = dallas.getDeviceCount();
    for (int role = 0; role < SENSOR_COUNT; role++) {
        DeviceAddress* a = roleAddr(role);
        if (!isZeroAddress(*a)) continue;
        for (int i = 0; i < busCount; i++) {
            DeviceAddress cand;
            if (!dallas.getAddress(cand, i)) continue;
            bool used = false;
            for (int r = 0; r < SENSOR_COUNT; r++) {
                if (!isZeroAddress(*roleAddr(r)) && memcmp(roleAddr(r), cand, 8) == 0) { used = true; break; }
            }
            if (!used) {
                memcpy(a, cand, 8);
                storage.saveSensorAddress(role, cand);
                Serial.printf("[Sensors] AUTO: role %d (%s) <- bus index %d (saved)\n", role, names[role], i);
                break;
            }
        }
    }

    for (int role = 0; role < SENSOR_COUNT; role++) {
        DeviceAddress* a = roleAddr(role);
        if (isZeroAddress(*a)) {
            Serial.printf("[Sensors] Role %d (%s): NOT ASSIGNED\n", role, names[role]);
        } else {
            Serial.printf("[Sensors] Role %d (%s): ", role, names[role]);
            for (int b = 0; b < 8; b++) Serial.printf("%02X", (*a)[b]);
            Serial.println();
        }
    }
}

// ===== Сканирование шины (для калибровки с экрана) =====
void Sensors::scanBus() {
    dallas.begin();                 // ← ПРИНУДИТЕЛЬНЫЙ повторный поиск по шине
    dallas.setResolution(12);       // сохраняем разрешение 12 бит

    discoveredCount = dallas.getDeviceCount();
    if (discoveredCount > 10) discoveredCount = 10;

    for (int i = 0; i < discoveredCount; i++) {
        DeviceAddress addr;
        if (dallas.getAddress(addr, i)) memcpy(discovered[i], addr, 8);
    }
    Serial.printf("[Sensors] Bus scan: %d sensors\n", discoveredCount);
}

int Sensors::getBusCount() { return discoveredCount; }

int8_t Sensors::getRoleBusIndex(uint8_t role) {
    DeviceAddress* a = roleAddr(role);
    if (!a || isZeroAddress(*a)) return -1;
    for (int i = 0; i < discoveredCount; i++) {
        if (memcmp(discovered[i], *a, 8) == 0) return (int8_t)i;
    }
    return -1;
}

void Sensors::setRoleBusIndex(uint8_t role, int8_t idx) {
    DeviceAddress* a = roleAddr(role);
    if (!a) return;

    if (idx < 0 || idx >= discoveredCount) {
        memset(a, 0, 8);
        Serial.printf("[Sensors] Role %d unassigned\n", role);
        return;
    }
    for (int r = 0; r < SENSOR_COUNT; r++) {
        if (r != (int)role && memcmp(roleAddr(r), discovered[idx], 8) == 0) {
            memset(roleAddr(r), 0, 8);
            Serial.printf("[Sensors] Role %d cleared (sensor moved to role %d)\n", r, role);
        }
    }
    memcpy(a, discovered[idx], 8);
    Serial.printf("[Sensors] Role %d <- bus index %d\n", role, idx);
}

void Sensors::cycleRoleBusIndex(uint8_t role, int8_t dir) {
    if (discoveredCount == 0) return;
    if (role >= SENSOR_COUNT) return;

    // 1. Собираем список ДОСТУПНЫХ индексов для этой роли
    //    Включает: все свободные датчики + текущий датчик этой роли + спец. индекс -1 ("---")
    int8_t available[12];   // максимум 10 датчиков + "---" + запас
    int availCount = 0;

    int8_t currentIdx = getRoleBusIndex(role);

    // Добавляем спец. индекс "---" (не назначен)
    available[availCount++] = -1;

    // Добавляем все свободные датчики (не занятые другими ролями)
    for (int i = 0; i < discoveredCount; i++) {
        bool usedByOther = false;
        for (int r = 0; r < SENSOR_COUNT; r++) {
            if (r == (int)role) continue;  // свою роль игнорируем
            if (getRoleBusIndex(r) == i) {
                usedByOther = true;
                break;
            }
        }
        if (!usedByOther) {
            available[availCount++] = (int8_t)i;
        }
    }

    // Добавляем текущий датчик этой роли (даже если он "занят" — это её собственный)
    if (currentIdx >= 0) {
        bool alreadyInList = false;
        for (int i = 0; i < availCount; i++) {
            if (available[i] == currentIdx) { alreadyInList = true; break; }
        }
        if (!alreadyInList) {
            available[availCount++] = currentIdx;
        }
    }

    // 2. Находим текущий индекс в списке доступных
    int curPos = -1;
    for (int i = 0; i < availCount; i++) {
        if (available[i] == currentIdx) { curPos = i; break; }
    }
    if (curPos < 0) curPos = 0;  // если не нашли — начинаем с начала

    // 3. Сдвигаем по направлению (+1 или -1) с циклическим переходом
    int newPos = curPos + dir;
    if (newPos >= availCount) newPos = 0;
    if (newPos < 0) newPos = availCount - 1;

    int8_t newIdx = available[newPos];

    // 4. Назначаем новый индекс (функция setRoleBusIndex сама освободит старую роль, если датчик был занят)
    setRoleBusIndex(role, newIdx);

    // 5. Отладочный вывод
    const char* roleNames[SENSOR_COUNT] = {
        "Комната", "Котёл", "Пол", "ТА", "Улица"
    };
    Serial.printf("[Sensors] Role %d (%s): %d -> %d  (available: %d items)\n",
                  role, roleNames[role], currentIdx, newIdx, availCount);
}

float Sensors::getBusTemp(uint8_t idx) {
    if (idx < 0 || idx >= discoveredCount) return 0.0;
    return dallas.getTempC(discovered[idx]);
}

void Sensors::saveAllAddresses() {
    for (int r = 0; r < SENSOR_COUNT; r++) {
        DeviceAddress* a = roleAddr(r);
        if (!a) continue;
        if (isZeroAddress(*a)) storage.removeSensorAddress(r);
        else storage.saveSensorAddress(r, *a);
    }
    Serial.println("[Sensors] All sensor addresses saved to NVS");
}

// ===== Опрос температур =====
float Sensors::readRole(const DeviceAddress &addr, bool &valid) {
    if (isZeroAddress(addr)) { valid = false; return 0.0; }
    float t = dallas.getTempC(addr);
    valid = isValidTemperature(t);
    return t;
}

bool Sensors::isValidTemperature(float temp) {
    return temp > -50.0 && temp < 150.0 && temp != 85.0;
}

void Sensors::update() {
    dallas.requestTemperatures();

    data.room        = readRole(addresses.room,        data.room_valid);
    data.boiler      = readRole(addresses.boiler,      data.boiler_valid);
    data.floor       = readRole(addresses.floor,       data.floor_valid);
    data.accumulator = readRole(addresses.accumulator, data.accumulator_valid);
    data.outdoor     = readRole(addresses.outdoor,     data.outdoor_valid);

    data.lastUpdate = millis();

    Serial.printf("[Sensors] R:%.1f(%d) B:%.1f(%d) F:%.1f(%d) TA:%.1f(%d) O:%.1f(%d)\n",
                  data.room, data.room_valid,
                  data.boiler, data.boiler_valid,
                  data.floor, data.floor_valid,
                  data.accumulator, data.accumulator_valid,
                  data.outdoor, data.outdoor_valid);
}

SensorData Sensors::getData() { return data; }

bool Sensors::isSensorValid(uint8_t role) {
    switch (role) {
        case ROLE_ROOM: return data.room_valid;
        case ROLE_BOILER: return data.boiler_valid;
        case ROLE_FLOOR: return data.floor_valid;
        case ROLE_ACCUMULATOR: return data.accumulator_valid;
        case ROLE_OUTDOOR: return data.outdoor_valid;
        default: return false;
    }
}

float Sensors::getTemperature(uint8_t role) {
    switch (role) {
        case ROLE_ROOM: return data.room;
        case ROLE_BOILER: return data.boiler;
        case ROLE_FLOOR: return data.floor;
        case ROLE_ACCUMULATOR: return data.accumulator;
        case ROLE_OUTDOOR: return data.outdoor;
        default: return 0;
    }
}

void Sensors::getAddress(uint8_t role, DeviceAddress &addr) {
    DeviceAddress* a = roleAddr(role);
    if (a) memcpy(addr, *a, 8); else memset(addr, 0, 8);
}

int Sensors::getSensorCount() { return dallas.getDeviceCount(); }

// ===== Калибровка через Serial (оставлена для отладки) =====
void Sensors::startCalibration() {
    Serial.println("[Sensors] === CALIBRATION MODE ===");
    scanBus();
    for (int i = 0; i < discoveredCount; i++) {
        Serial.printf("  [%d] ", i);
        for (int j = 0; j < 8; j++) Serial.printf("%02X", discovered[i][j]);
        Serial.printf("  %.2f°C\n", dallas.getTempC(discovered[i]));
    }
    calibrating = true;
    Serial.println("Roles: 0=Room, 1=Boiler, 2=Floor, 3=Accumulator, 4=Outdoor");
    Serial.println("Use: assign <role> <index>");
}

void Sensors::assignSensorToRole(uint8_t role, uint8_t idx) {
    if (role >= SENSOR_COUNT) { Serial.printf("[Sensors] ERROR: invalid role %d\n", role); return; }
    if (idx >= discoveredCount) { Serial.printf("[Sensors] ERROR: index %d not found\n", idx); return; }
    setRoleBusIndex(role, (int8_t)idx);
    DeviceAddress* a = roleAddr(role);
    storage.saveSensorAddress(role, *a);
    Serial.printf("[Sensors] Sensor %d assigned to role %d and saved\n", idx, role);
}

bool Sensors::isCalibrating() { return calibrating; }

void Sensors::printAllSensors() {
    Serial.println("=== Current Assignments ===");
    auto p = [&](const char* n, uint8_t r) {
        DeviceAddress* a = roleAddr(r);
        Serial.printf("%s: ", n);
        if (isZeroAddress(*a)) Serial.printf("NOT ASSIGNED\n");
        else {
            for (int i = 0; i < 8; i++) Serial.printf("%02X", (*a)[i]);
            Serial.printf("\n");
        }
    };
    p("Room       ", ROLE_ROOM);
    p("Boiler     ", ROLE_BOILER);
    p("Floor      ", ROLE_FLOOR);
    p("Accumulator", ROLE_ACCUMULATOR);
    p("Outdoor    ", ROLE_OUTDOOR);
}