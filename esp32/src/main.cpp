#include <Arduino.h>
#include "config.h"
#include "storage.h"
#include "sensors.h"
#include "control.h"
#include "network.h"
#include "nextion.h"
#include "timekeeper.h"
#include <freertos/semphr.h> // Добавляем заголовок для FreeRTOS семафоров

void taskControl(void *parameter);
void taskSensor(void *parameter);
void taskNetwork(void *parameter);
void taskNextion(void *parameter);

TaskHandle_t taskControlHandle = NULL;
TaskHandle_t taskSensorHandle = NULL;
TaskHandle_t taskNetworkHandle = NULL;
TaskHandle_t taskNextionHandle = NULL;

// Глобальный семафор для защиты доступа к настройкам
SemaphoreHandle_t settingsMtx;

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println("\n========================================");
    Serial.println("  ESP32 Heating System Controller");
    Serial.printf("  Firmware: %s\n", FIRMWARE_VERSION);
    Serial.printf("  Device ID: %s\n", DEVICE_ID);
    Serial.println("========================================\n");

    // Инициализация семафора
    settingsMtx = xSemaphoreCreateMutex();
    if(settingsMtx == NULL) {
        Serial.println("[main] ❌ Не удалось создать мьютекс для настроек!");
    } else {
        Serial.println("[main] ✅ Мьютекс для настроек успешно создан.");
    }

    storage.begin();
    storage.loadSettings(control.settings);

    sensors.begin();
    control.begin();
    network.begin();
    nextion.begin();
    timekeeper.begin();

    Serial.println("[Main] Creating FreeRTOS tasks...\n");

    xTaskCreatePinnedToCore(taskControl, "TaskControl", TASK_CONTROL_STACK, NULL,
                            TASK_CONTROL_PRIORITY, &taskControlHandle, 1);
    xTaskCreatePinnedToCore(taskSensor, "TaskSensor", TASK_SENSOR_STACK, NULL,
                            TASK_SENSOR_PRIORITY, &taskSensorHandle, 1);
    xTaskCreatePinnedToCore(taskNextion, "TaskNextion", TASK_NEXTION_STACK, NULL,
                            TASK_NEXTION_PRIORITY, &taskNextionHandle, 1);
    xTaskCreatePinnedToCore(taskNetwork, "TaskNetwork", TASK_NETWORK_STACK, NULL,
                            TASK_NETWORK_PRIORITY, &taskNetworkHandle, 0);

    Serial.println("[Main] All tasks created. System started!\n");
}

void loop() {
    vTaskDelay(1000 / portTICK_PERIOD_MS);
}

void taskControl(void *parameter) {
    Serial.println("[TaskControl] Started");
    for (;;) {
        control.update();

        // ===== ОБРАБОТКА КОМАНД ОТ СЕРВЕРА =====
        while (network.hasPendingCommands()) {
            ServerCommand cmd = network.getNextCommand();
            
            if (cmd.type == "SET_SETTING") {
                bool updated = false;
                String key = cmd.payloadKey;
                float value = cmd.payloadValue;
                
                Serial.printf("[TaskControl] 📥 Получена команда SET_SETTING: key='%s', value=%f\n", 
                              key.c_str(), value);
                
                // ===== ПОЛНЫЙ МАППИНГ КЛЮЧЕЙ ИЗ API.md =====
                
                // --- ТТ котёл (Boiler) ---
                if (key == "boiler_temp_threshold_on") {
                    control.settings.boiler_threshold_on = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Boiler threshold ON: %.1f°C\n", value);
                }
                else if (key == "boiler_temp_threshold_off") {
                    control.settings.boiler_threshold_off = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Boiler threshold OFF: %.1f°C\n", value);
                }
                else if (key == "boiler_temp_target" || key == "boiler_temp_hysteresis") {
                    Serial.printf("[TaskControl] ℹ️ Key '%s' received but not used by ESP32\n", key.c_str());
                    updated = true;
                }
                
                // --- Тёплый пол (Floor) ---
                else if (key == "floor_temp_threshold_on" || key == "floor_pump_on_temp") {
                    control.settings.floor_threshold_on = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Floor threshold ON: %.1f°C\n", value);
                }
                else if (key == "floor_temp_threshold_off" || key == "floor_pump_off_temp") {
                    control.settings.floor_threshold_off = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Floor threshold OFF: %.1f°C\n", value);
                }
                else if (key == "floor_temp_target" || key == "floor_temp_hysteresis") {
                    Serial.printf("[TaskControl] ℹ️ Key '%s' received but not used by ESP32\n", key.c_str());
                    updated = true;
                }
                
                // --- Помещение (Room) ---
                else if (key == "room_temp_threshold_on") {
                    control.settings.room_target_on = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Room threshold ON: %.1f°C\n", value);
                }
                else if (key == "room_temp_threshold_off") {
                    control.settings.room_target_off = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Room threshold OFF: %.1f°C\n", value);
                }
                else if (key == "room_temp_target" || key == "room_temp_hysteresis") {
                    Serial.printf("[TaskControl] ℹ️ Key '%s' received but not used by ESP32\n", key.c_str());
                    updated = true;
                }
                
                // --- Теплоаккумулятор (Accumulator / ТА) ---
                else if (key == "accumulator_temp_threshold_on") {
                    control.settings.TA_target_on = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Accumulator threshold ON: %.1f°C\n", value);
                }
                else if (key == "accumulator_temp_threshold_off") {
                    control.settings.TA_target_off = value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Accumulator threshold OFF: %.1f°C\n", value);
                }
                else if (key == "accumulator_temp_target" || key == "accumulator_temp_hysteresis") {
                    Serial.printf("[TaskControl] ℹ️ Key '%s' received but not used by ESP32\n", key.c_str());
                    updated = true;
                }
                
                // --- Ночной режим ---
                else if (key == "night_start") {
                    Serial.printf("[TaskControl] ℹ️ Key 'night_start' is string, use Nextion to change\n");
                    updated = true;
                }
                else if (key == "night_end") {
                    Serial.printf("[TaskControl] ℹ️ Key 'night_end' is string, use Nextion to change\n");
                    updated = true;
                }
                
                // --- Ручное управление ---
                else if (key == "manual_timeout") {
                    control.settings.manual_timeout = (uint16_t)value;
                    updated = true;
                    Serial.printf("[TaskControl] ✅ Manual timeout: %d sec\n", (uint16_t)value);
                }
                
                // --- Неизвестный ключ ---
                else {
                    Serial.printf("[TaskControl] ⚠️ Unknown setting key: '%s'\n", key.c_str());
                    network.acknowledgeCommand(cmd.id, false, "Unknown setting key");
                    continue;
                }
                
                // ===== СОХРАНЕНИЕ И ПОДТВЕРЖДЕНИЕ =====
                if (updated) {
                    storage.saveSettings(control.settings);
                    control.clearAllManualOverrides();
                    network.acknowledgeCommand(cmd.id, true, "Setting updated");
                    Serial.printf("[TaskControl] ✅ Setting '%s' updated to %f\n", cmd.payloadKey.c_str(), cmd.payloadValue);
                    
                    // 🚀 ФОРСИРОВАННЫЙ SYNC: отправим новые настройки на сервер через 5 секунд
                    network.lastHeartbeat -= 55000;
                    Serial.println("[TaskControl] 🚀 Forced sync triggered (next heartbeat in 5s)");
                }
            }
            
            // ===== УПРАВЛЕНИЕ УСТРОЙСТВАМИ =====
            else if (cmd.type == "CONTROL_DEVICE") {
                bool state = (cmd.payloadAction == "on");
                
                if (cmd.payloadDevice == "boiler") {
                    control.setManualOverride(DEV_BOILER, state);
                    Serial.printf("[TaskControl] 🎮 Boiler manual: %s\n", state ? "ON" : "OFF");
                }
                else if (cmd.payloadDevice == "elec_boiler") {
                    control.setManualOverride(DEV_ELEC_BOILER, state);
                    Serial.printf("[TaskControl] 🎮 ElecBoiler manual: %s\n", state ? "ON" : "OFF");
                }
                else if (cmd.payloadDevice == "floor_pump") {
                    control.setManualOverride(DEV_FLOOR_PUMP, state);
                    Serial.printf("[TaskControl] 🎮 FloorPump manual: %s\n", state ? "ON" : "OFF");
                }
                else if (cmd.payloadDevice == "radiator_pump") {
                    control.setManualOverride(DEV_RADIATOR_PUMP, state);
                    Serial.printf("[TaskControl] 🎮 RadiatorPump manual: %s\n", state ? "ON" : "OFF");
                }
                else {
                    Serial.printf("[TaskControl] ⚠️ Unknown device: '%s'\n", cmd.payloadDevice.c_str());
                    network.acknowledgeCommand(cmd.id, false, "Unknown device");
                    continue;
                }
                
                network.acknowledgeCommand(cmd.id, true, "Device controlled");
            }
            
            // ===== АВАРИЙНАЯ ОСТАНОВКА =====
            else if (cmd.type == "EMERGENCY_STOP") {
                control.emergencyStop();
                Serial.println("[TaskControl] 🚨 EMERGENCY STOP activated from server!");
                network.acknowledgeCommand(cmd.id, true, "Emergency stop");
            }
            
            // ===== ЗАПРОС ПОЛНОЙ СИНХРОНИЗАЦИИ =====
            else if (cmd.type == "REQUEST_FULL_SYNC") {
                Serial.println("[TaskControl] 🔄 Full sync requested by server");
                network.syncWithServer();
                network.acknowledgeCommand(cmd.id, true, "Full sync completed");
            }
            
            // ===== ПЕРЕЗАГРУЗКА ESP32 =====
            else if (cmd.type == "REBOOT") {
                Serial.println("[TaskControl] 🔄 Reboot requested by server");
                network.acknowledgeCommand(cmd.id, true, "Rebooting...");
                delay(1000);
                ESP.restart();
            }
            
            // ===== НЕИЗВЕСТНЫЙ ТИП КОМАНДЫ =====
            else {
                Serial.printf("[TaskControl] ⚠️ Unknown command type: '%s'\n", cmd.type.c_str());
                network.acknowledgeCommand(cmd.id, false, "Unknown command type");
            }
        }

        // ===== КНОПКА КАЛИБРОВКИ (GPIO 0) =====
        if (digitalRead(PIN_BUTTON_CALIB) == LOW) {
            delay(50);
            if (digitalRead(PIN_BUTTON_CALIB) == LOW) {
                Serial.println("[TaskControl] 🔧 Calibration button pressed!");
                sensors.startCalibration();
                while (digitalRead(PIN_BUTTON_CALIB) == LOW) {
                    vTaskDelay(100 / portTICK_PERIOD_MS);
                }
            }
        }
        
        vTaskDelay(CONTROL_INTERVAL / portTICK_PERIOD_MS);
    }
}

void taskSensor(void *parameter) {
    Serial.println("[TaskSensor] Started");
    for (;;) {
        sensors.update();
        vTaskDelay(SENSOR_READ_INTERVAL / portTICK_PERIOD_MS);
    }
}

// ===== ИСПРАВЛЕННАЯ ФУНКЦИЯ taskNetwork (одна, без дублирования) =====
void taskNetwork(void *parameter) {
    Serial.println("[TaskNetwork] Started");
    vTaskDelay(5000 / portTICK_PERIOD_MS);
    
    // Первая попытка связи с сервером
    network.syncWithServer();
    
    for (;;) {
        // 1. Проверка Wi-Fi и heartbeat (включая форсированный sync)
        network.update();
        
        // 2. 🆕 НОВОЕ: Если сервер прислал флаг обновления, запускаем OTA
        if (network.hasOtaUpdate()) {
            Serial.println("[TaskNetwork] 🚀 Запуск OTA обновления по команде сервера...");
            bool success = network.performOTA();
            if (!success) {
                Serial.println("[TaskNetwork] ❌ OTA не удалась, повторим при следующем sync");
            }
            // Если success == true, ESP32 перезагрузится сам внутри performOTA()
        }
        
        // 3. TimeKeeper сам управляет NTP синхронизацией по своим внутренним таймерам (раз в 6 часов).
        timekeeper.update();
        
        // 4. Короткая задержка для быстрой реакции на форсированный sync (500 мс)
        vTaskDelay(500 / portTICK_PERIOD_MS);
    }
}

void taskNextion(void *parameter) {
    Serial.println("[TaskNextion] Started");
    for (;;) {
        nextion.update();

        while (nextion.hasCommand()) {
            String rawCmd = nextion.getCommand();
            String cmd = "";
            for (int i = 0; i < rawCmd.length(); i++) {
                char c = rawCmd.charAt(i);
                if (c >= 32 && c <= 126) cmd += c;
            }
            if (cmd.length() == 0) continue;
            Serial.printf("[TaskNextion] Command: '%s'\n", cmd.c_str());

            // === Страницы ===
            if (cmd == "pg0") { nextion.setPage(0); }
            else if (cmd == "pg1") { nextion.setPage(1); }
            else if (cmd == "pg2") { nextion.setPage(2); }
            else if (cmd == "pg3") { nextion.setPage(3); }
            else if (cmd == "pg4") { nextion.setPage(4); }
            else if (cmd == "pg5") { nextion.setPage(5); }
            else if (cmd == "pg6") { nextion.setPage(6); }
            else if (cmd == "pg7") { nextion.setPage(7); }

            // === Ручное управление ===
            else if (cmd == "manual_boiler_on")  control.setManualOverride(DEV_BOILER, true);
            else if (cmd == "manual_boiler_off") control.setManualOverride(DEV_BOILER, false);
            else if (cmd == "manual_elec_on")    control.setManualOverride(DEV_ELEC_BOILER, true);
            else if (cmd == "manual_elec_off")   control.setManualOverride(DEV_ELEC_BOILER, false);
            else if (cmd == "manual_floor_on")   control.setManualOverride(DEV_FLOOR_PUMP, true);
            else if (cmd == "manual_floor_off")  control.setManualOverride(DEV_FLOOR_PUMP, false);
            else if (cmd == "manual_room_on"     || cmd == "manual_radiator_on"  || cmd == "manual_rad_on")  control.setManualOverride(DEV_RADIATOR_PUMP, true);
            else if (cmd == "manual_room_off"    || cmd == "manual_radiator_off" || cmd == "manual_rad_off") control.setManualOverride(DEV_RADIATOR_PUMP, false);
            else if (cmd == "emergency_stop")    control.emergencyStop();

            // === Калибровка датчиков ===
            else if (cmd == "cal_scan")  { sensors.scanBus(); }
            else if (cmd == "cal_save")  { sensors.saveAllAddresses(); }
            else if (cmd.startsWith("cal_inc_")) { sensors.cycleRoleBusIndex((uint8_t)cmd.substring(8).toInt(), +1); }
            else if (cmd.startsWith("cal_dec_")) { sensors.cycleRoleBusIndex((uint8_t)cmd.substring(8).toInt(), -1); }

            // === Настройки +/− ===
            else if (cmd == "inc_bon") { control.settings.boiler_threshold_on  += 0.5; }
            else if (cmd == "inc_bof") { control.settings.boiler_threshold_off += 0.5; }
            else if (cmd == "inc_fon") { control.settings.floor_threshold_on   += 0.5; }
            else if (cmd == "inc_fof") { control.settings.floor_threshold_off  += 0.5; }
            else if (cmd == "inc_ron") { control.settings.room_target_on       += 0.5; }
            else if (cmd == "inc_rof") { control.settings.room_target_off      += 0.5; }
            else if (cmd == "inc_aon") { control.settings.TA_target_on         += 0.5; }
            else if (cmd == "inc_aof") { control.settings.TA_target_off        += 0.5; }
            else if (cmd == "inc_tm")  { control.settings.manual_timeout       += 5;   }
            else if (cmd == "dec_bon") { control.settings.boiler_threshold_on  -= 0.5; }
            else if (cmd == "dec_bof") { control.settings.boiler_threshold_off -= 0.5; }
            else if (cmd == "dec_fon") { control.settings.floor_threshold_on   -= 0.5; }
            else if (cmd == "dec_fof") { control.settings.floor_threshold_off  -= 0.5; }
            else if (cmd == "dec_ron") { control.settings.room_target_on       -= 0.5; }
            else if (cmd == "dec_rof") { control.settings.room_target_off      -= 0.5; }
            else if (cmd == "dec_aon") { control.settings.TA_target_on         -= 0.5; }
            else if (cmd == "dec_aof") { control.settings.TA_target_off        -= 0.5; }
            else if (cmd == "dec_tm")  { control.settings.manual_timeout       -= 5;   }

           else if (cmd == "save_set") {
                if (control.settings.boiler_threshold_on  < 5.0)  control.settings.boiler_threshold_on  = 5.0;
                if (control.settings.boiler_threshold_on  > 95.0) control.settings.boiler_threshold_on  = 95.0;
                if (control.settings.boiler_threshold_off < 5.0)  control.settings.boiler_threshold_off = 5.0;
                if (control.settings.boiler_threshold_off > 95.0) control.settings.boiler_threshold_off = 95.0;
                if (control.settings.floor_threshold_on   < 5.0)  control.settings.floor_threshold_on   = 5.0;
                if (control.settings.floor_threshold_on   > 95.0) control.settings.floor_threshold_on   = 95.0;
                if (control.settings.floor_threshold_off  < 5.0)  control.settings.floor_threshold_off  = 5.0;
                if (control.settings.floor_threshold_off  > 95.0) control.settings.floor_threshold_off  = 95.0;
                if (control.settings.room_target_on       < 5.0)  control.settings.room_target_on       = 5.0;
                if (control.settings.room_target_on       > 95.0) control.settings.room_target_on       = 95.0;
                if (control.settings.room_target_off      < 5.0)  control.settings.room_target_off      = 5.0;
                if (control.settings.room_target_off      > 95.0) control.settings.room_target_off      = 95.0;
                if (control.settings.TA_target_on         < 5.0)  control.settings.TA_target_on         = 5.0;
                if (control.settings.TA_target_on         > 95.0) control.settings.TA_target_on         = 95.0;
                if (control.settings.TA_target_off        < 5.0)  control.settings.TA_target_off        = 5.0;
                if (control.settings.TA_target_off        > 95.0) control.settings.TA_target_off        = 95.0;
                if (control.settings.manual_timeout       < 10)   control.settings.manual_timeout       = 10;
                if (control.settings.manual_timeout       > 300)  control.settings.manual_timeout       = 300;
                storage.saveSettings(control.settings);
                control.clearAllManualOverrides();
                Serial.println("[TaskNextion] Settings saved to NVS");
                
                // 🚀 ФОРСИРОВАННЫЙ SYNC: следующий heartbeat произойдёт через 5 секунд
                network.lastHeartbeat -= 55000;
                Serial.println("[TaskNextion] 🚀 Forced sync triggered (next heartbeat in 5s)");
            }

            // === Дата и время ===
            else if (cmd == "time_min_inc")  { timekeeper.adjustMinute(+1); }
            else if (cmd == "time_min_dec")  { timekeeper.adjustMinute(-1); }
            else if (cmd == "time_hour_inc") { timekeeper.adjustHour(+1); }
            else if (cmd == "time_hour_dec") { timekeeper.adjustHour(-1); }
            else if (cmd == "time_day_inc")  { timekeeper.adjustDay(+1); }
            else if (cmd == "time_day_dec")  { timekeeper.adjustDay(-1); }
            else if (cmd == "time_mon_inc")  { timekeeper.adjustMonth(+1); }
            else if (cmd == "time_mon_dec")  { timekeeper.adjustMonth(-1); }
            else if (cmd == "time_year_inc") { timekeeper.adjustYear(+1); }
            else if (cmd == "time_year_dec") { timekeeper.adjustYear(-1); }
            else if (cmd == "time_sync_ntp") { Serial.println("[TaskNextion] NTP sync requested"); }
            else if (cmd == "time_save")     { Serial.println("[TaskNextion] Time saved"); }

            // === Расписание (Page 7) ===
            else if (cmd == "sch_dev_0") { nextion.scheduleDevice = 0; }
            else if (cmd == "sch_dev_1") { nextion.scheduleDevice = 1; }
            else if (cmd == "sch_dev_2") { nextion.scheduleDevice = 2; }
            else if (cmd == "sch_dev_3") { nextion.scheduleDevice = 3; }

            else if (cmd.startsWith("sch_chk_")) {
                int slot = cmd.substring(8).toInt();
                control.toggleSlotEnabled(nextion.scheduleDevice, slot);
                storage.saveSettings(control.settings);
            }
            else if (cmd.startsWith("sch_edit_")) {
                int slot = cmd.substring(9).toInt();
                nextion.showKeypad(nextion.scheduleDevice, slot, "ЧЧ:ММ-ЧЧ:ММ");
            }

            // 🆕 Сохранение расписания (аналогично cal_save)
            else if (cmd == "sch_save") {
                storage.saveSettings(control.settings);
                Serial.println("[TaskNextion] ✅ Schedule saved to NVS");
            }

            // === Клавиатура (Page 8) ===
            else if (cmd.startsWith("key_")) {
                nextion.handleKeypadInput(cmd);
                if (cmd == "key_ok" || cmd == "key_clear") {
                    storage.saveSettings(control.settings);
                }
            }

            // === Отладка ===
            else if (cmd == "calibrate") { sensors.startCalibration(); }
            else if (cmd.startsWith("assign ")) {
                int firstSpace = cmd.indexOf(' ', 7);
                if (firstSpace > 0) {
                    int role = cmd.substring(7, firstSpace).toInt();
                    int idx  = cmd.substring(firstSpace + 1).toInt();
                    sensors.assignSensorToRole(role, idx);
                }
            }
            else {
                Serial.printf("[TaskNextion] Unknown command: '%s'\n", cmd.c_str());
            }
        }
        vTaskDelay(NEXTION_UPDATE_INTERVAL / portTICK_PERIOD_MS);
    }
}