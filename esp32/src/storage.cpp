#include "storage.h"
#include "main.h"   // для extern SemaphoreHandle_t settingsMtx

Storage storage;

void Storage::begin() {
    prefs.begin("heating", false);
    Serial.println("[Storage] Initialized");
}

void Storage::loadSettings(SystemSettings &s) {
    s.boiler_threshold_on  = prefs.getFloat("boiler_on",  55.0);
    s.boiler_threshold_off = prefs.getFloat("boiler_off", 65.0);
    s.floor_threshold_on   = prefs.getFloat("floor_on",  24.0);
    s.floor_threshold_off  = prefs.getFloat("floor_off", 26.0);
    s.room_target_on       = prefs.getFloat("room_on",   21.5);
    s.room_target_off      = prefs.getFloat("room_off",  22.5);
    s.TA_target_on         = prefs.getFloat("ta_on",     64.0);
    s.TA_target_off        = prefs.getFloat("ta_off",    66.0);
    s.manual_timeout       = prefs.getUShort("manual_timeout", 30);

    char buf[10];
    if (prefs.getString("night_start", buf, sizeof(buf)) > 0) {
        strncpy(s.night_start, buf, sizeof(s.night_start));
        s.night_start[sizeof(s.night_start) - 1] = '\0';
    }
    if (prefs.getString("night_end", buf, sizeof(buf)) > 0) {
        strncpy(s.night_end, buf, sizeof(s.night_end));
        s.night_end[sizeof(s.night_end) - 1] = '\0';
    }

    // 🆕 НОВОЕ: Загрузка расписания из NVS
    size_t schSize = prefs.getBytesLength("schedule_blob");
    if (schSize > 0 && schSize == sizeof(s.schedule)) {
        prefs.getBytes("schedule_blob", &s.schedule, sizeof(s.schedule));
        Serial.println("[Storage] ✅ Schedule loaded from NVS");
    } else {
        Serial.println("[Storage] ⚠️ Schedule not found in NVS, using defaults");
    }

    Serial.println("[Storage] Settings loaded");
}

void Storage::saveSettings(const SystemSettings &s) {
    // Захватываем мьютекс перед сохранением настроек
    if(xSemaphoreTake(settingsMtx, portMAX_DELAY) == pdTRUE) {
        prefs.putFloat("boiler_on",  s.boiler_threshold_on);
        prefs.putFloat("boiler_off", s.boiler_threshold_off);
        prefs.putFloat("floor_on",   s.floor_threshold_on);
        prefs.putFloat("floor_off",  s.floor_threshold_off);
        prefs.putFloat("room_on",    s.room_target_on);
        prefs.putFloat("room_off",   s.room_target_off);
        prefs.putFloat("ta_on",      s.TA_target_on);
        prefs.putFloat("ta_off",     s.TA_target_off);
        prefs.putUShort("manual_timeout", s.manual_timeout);
        prefs.putString("night_start", s.night_start);
        prefs.putString("night_end",   s.night_end);

        // 🆕 НОВОЕ: Сохранение расписания в NVS как массив байт
        prefs.putBytes("schedule_blob", &s.schedule, sizeof(s.schedule));
        
        Serial.println("[Storage] ✅ Settings and Schedule saved to NVS");

        // Освобождаем мьютекс после сохранения
        xSemaphoreGive(settingsMtx);
    } else {
        Serial.println("[Storage] ❌ Не удалось захватить мьютекс для сохранения настроек!");
    }
}

void Storage::saveSensorAddress(uint8_t role, const DeviceAddress &addr) {
    char key[20];
    snprintf(key, sizeof(key), "sensor_%d", role);
    prefs.putBytes(key, (void*)addr, 8);
}

bool Storage::loadSensorAddress(uint8_t role, DeviceAddress &addr) {
    char key[20];
    snprintf(key, sizeof(key), "sensor_%d", role);
    return prefs.getBytes(key, addr, 8) == 8;
}

bool Storage::hasSensorAddress(uint8_t role) {
    char key[20];
    snprintf(key, sizeof(key), "sensor_%d", role);
    return prefs.isKey(key);
}

void Storage::removeSensorAddress(uint8_t role) {
    char key[20];
    snprintf(key, sizeof(key), "sensor_%d", role);
    prefs.remove(key);
}

void Storage::clearSensorAddresses() {
    for (int i = 0; i < SENSOR_COUNT; i++) {
        char key[20];
        snprintf(key, sizeof(key), "sensor_%d", i);
        prefs.remove(key);
    }
}

void Storage::saveDeviceStates(bool boiler, bool floor, bool radiator, bool elec) {
    prefs.putBool("state_boiler", boiler);
    prefs.putBool("state_floor", floor);
    prefs.putBool("state_radiator", radiator);
    prefs.putBool("state_elec", elec);
}

void Storage::loadDeviceStates(bool &boiler, bool &floor, bool &radiator, bool &elec) {
    boiler   = prefs.getBool("state_boiler", false);
    floor    = prefs.getBool("state_floor", false);
    radiator = prefs.getBool("state_radiator", false);
    elec     = prefs.getBool("state_elec", false);
}