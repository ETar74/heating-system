#include "network.h"
#include "timekeeper.h"
#include "sensors.h"
#include "control.h"
#include <HTTPUpdate.h>  // 🆕 НОВОЕ: Библиотека для OTA обновлений
#include <LITTLEFS.h>

Network network;

void Network::begin() {
    connectWiFi();
    lastHeartbeat = 0;
    lastWifiCheck = 0;
    cmdCount = 0;
    cmdHead = 0;
    // Инициализация буфера телеметрии
    initTelemetryBuffer();
    lastBufferedTime = 0;
}

void Network::connectWiFi() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    Serial.printf("[Network] Подключение к Wi-Fi: '%s'...\\n", WIFI_SSID);

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        wifiConnected = true;
        Serial.printf("\\n[Network] ✅ Wi-Fi подключен! IP адрес ESP32: %s\\n", WiFi.localIP().toString().c_str());

        // 🆕 ВСТАВИТЬ СЮДА ТЕСТ TCP СОЕДИНЕНИЯ:
        WiFiClient testClient;
        Serial.printf("[Network] 🧪 Тест прямого TCP-соединения с %s:%d ...\\n", SERVER_HOST, SERVER_PORT);
        if (testClient.connect(SERVER_HOST, SERVER_PORT, 3000)) {
            Serial.println("[Network] ✅ TCP СОЕДИНЕНИЕ УСПЕШНО! Порт открыт, сеть работает.");
            testClient.stop();
        } else {
            Serial.println("[Network] ❌ TCP СОЕДИНЕНИЕ НЕВОЗМОЖНО! Телефон/сеть блокирует порт 3000.");
        }

        //needNtpSync = true;
    } else {
        wifiConnected = false;
        Serial.println("\\n[Network] ❌ ОШИБКА: Не удалось подключиться к Wi-Fi.");
    }
}

void Network::checkWiFi() {
    if (millis() - lastWifiCheck < WIFI_CHECK_INTERVAL) return;
    lastWifiCheck = millis();

    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[Network] ⚠️ Wi-Fi отключен, попытка переподключения...");
        wifiConnected = false;
        connectWiFi();
    } else {
        wifiConnected = true;
    }
}

void Network::update() {
    checkWiFi();
    // Periodic OTA check (once per hour)
    if (millis() - lastOtaCheck >= OTA_CHECK_INTERVAL_MS) {
        checkOtaUpdate();
    }
    if (!wifiConnected) {
        // Если Wi-Fi отключен, проверяем периодически (не используем backoff для Wi-Fi)
        if (millis() - lastWifiCheck >= WIFI_CHECK_INTERVAL) {
            checkWiFi();
        }
        return;
    }

    // Если подключены к Wi-Fi, но нет соединения с сервером, используем backoff
    if (!serverConnected) {
        // Store telemetry every 2 minutes when disconnected
        if (millis() - lastBufferedTime >= BUFFER_INTERVAL_MS) {
            SensorData d = sensors.getData();
            float vals[5] = { d.room, d.boiler, d.floor, d.accumulator, d.outdoor };
            uint32_t ts = millis() / 1000; // seconds since boot
            storeTelemetry(ts, vals);
            lastBufferedTime = millis();
        }

        if (retryDelay == 0) {
            // Первая попытка - устанавливаем начальную задержку
            retryDelay = NETWORK_BASE_RETRY_MS;
            retryCount = 0;
        }

        if (millis() - lastHeartbeat >= retryDelay) {
            lastHeartbeat = millis();
            if (syncWithServer()) {
                // Успех - сбрасываем backoff
                retryDelay = 0;
                retryCount = 0;
            } else {
                // Неудача - увеличиваем задержку
                retryCount++;
                if (retryCount >= NETWORK_MAX_RETRIES) {
                    retryCount = NETWORK_MAX_RETRIES;
                }
                // Экспоненциальная задержка с ограничением
                retryDelay = (uint32_t)(NETWORK_BASE_RETRY_MS * pow(NETWORK_RETRY_MULTIPLIER, retryCount));
                if (retryDelay > NETWORK_MAX_RETRY_MS) {
                    retryDelay = NETWORK_MAX_RETRY_MS;
                }
                Serial.printf("[Network] Backoff: попытка %d, задержка %lu мс\\n",
                              retryCount, retryDelay);
            }
        }
        return;
    }

    // Если подключены к Wi-Fi и есть соединение с сервером, проверяем heartbeat
    if (millis() - lastHeartbeat >= SERVER_HEARTBEAT) {
        lastHeartbeat = millis();
        if (!syncWithServer()) {
            // Если не удалось синхронизироваться, считаем, что соединение потеряно
            serverConnected = false;
            retryDelay = NETWORK_BASE_RETRY_MS;
            retryCount = 0;
        }
    }
}

bool Network::syncWithServer() {
    if (!wifiConnected) return false;
    Serial.println("[Network] 🔌 Попытка синхронизации с сервером...");

    if (sendSync()) {
        serverConnected = true;
        // После успешной отправки синхронизируем буфер телеметрии
        flushTelemetryBuffer();
        // Получить pending команды от сервера
        fetchCommands();
        return true;
    } else {
        serverConnected = false;
        Serial.println("[Network] ❌ Не удалось синхронизироваться с сервером.");
        return false;
    }
}

String Network::buildSyncPayload() {
    JsonDocument doc;
    SensorData d = sensors.getData();
    DeviceStates st = control.getStates();
    SystemSettings s = control.settings;

    doc["deviceId"] = DEVICE_ID;
    doc["timestamp"] = millis() / 1000;
    doc["uptime"] = millis() / 1000;
    doc["firmware"] = FIRMWARE_VERSION;

    JsonObject settings = doc["settings"].to<JsonObject>();
    settings["boiler_temp_threshold_on"]  = s.boiler_threshold_on;
    settings["boiler_temp_threshold_off"] = s.boiler_threshold_off;
    settings["boiler_temp_target"]        = s.boiler_threshold_on; // Для обратной совместимости

    settings["floor_temp_threshold_on"]   = s.floor_threshold_on;
    settings["floor_temp_threshold_off"]  = s.floor_threshold_off;
    settings["floor_temp_target"]         = s.floor_threshold_on;

    settings["room_temp_threshold_on"]    = s.room_target_on;
    settings["room_temp_threshold_off"]   = s.room_target_off;
    settings["room_temp_target"]          = s.room_target_on;

    settings["accumulator_temp_threshold_on"]  = s.TA_target_on;
    settings["accumulator_temp_threshold_off"] = s.TA_target_off;
    settings["accumulator_temp_target"]        = s.TA_target_on;

    settings["manual_timeout"] = s.manual_timeout;
    settings["night_start"]    = s.night_start;
    settings["night_end"]      = s.night_end;

    JsonObject telemetry = doc["telemetry"].to<JsonObject>();
    telemetry["room_temp"] = d.room;
    telemetry["boiler_temp"] = d.boiler;
    telemetry["floor_temp"] = d.floor;
    telemetry["accumulator_temp"] = d.accumulator;
    telemetry["outdoor_temp"] = d.outdoor;

    JsonObject deviceStatus = doc["device_status"].to<JsonObject>();
    deviceStatus["boiler"] = st.boiler ? "on" : "off";
    deviceStatus["elec_boiler"] = st.elec_boiler ? "on" : "off";
    deviceStatus["floor_pump"] = st.floor_pump ? "on" : "off";
    deviceStatus["radiator_pump"] = st.radiator_pump ? "on" : "off";

    JsonObject phases = doc["phases"].to<JsonObject>();
    phases["L1"] = control.phaseL1;
    phases["L2"] = control.phaseL2;
    phases["L3"] = control.phaseL3;

    JsonArray events = doc["events"].to<JsonArray>();
    while (control.hasPendingEvents() && events.size() < 5) {
        DeviceEvent e = control.getNextEvent();
        JsonObject ev = events.add<JsonObject>();
        ev["id"] = e.id;
        ev["timestamp"] = e.timestamp;
        ev["type"] = e.type;
        ev["message"] = e.message;
    }

    String output;
    serializeJson(doc, output);
    return output;
}

bool Network::fetchCommands() {
    HTTPClient http;
    // URL для получения pending команд
    String url = String("http://") + SERVER_HOST + ":" + SERVER_PORT + "/api/commands/pending";
    Serial.printf("[Network] 📡 Запрос pending команд (GET): %s\\n", url.c_str());

    http.begin(url);
    http.addHeader("Authorization", "Bearer " DEVICE_TOKEN);
    http.setTimeout(5000);
    int httpCode = http.GET();

    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        Serial.printf("[Network] ✅ Получено pending команд. Длина: %d\\n", response.length());

        JsonDocument doc;
        DeserializationError error = deserializeJson(doc, response);

        if (!error && doc.is<JsonArray>()) {
            JsonArray commands = doc.as<JsonArray>();
            for (JsonObject cmd : commands) {
                if (cmdCount < 10) {
                    ServerCommand &sc = commandQueue[(cmdHead + cmdCount) % 10];
                    sc.id = cmd["id"];
                    sc.type = cmd["type"].as<String>();

                    JsonObject p = cmd["payload"];
                    if (p["key"].is<const char*>()) {
                        sc.payloadKey = p["key"].as<String>();
                        sc.payloadValue = p["value"];
                    }
                    if (p["device"].is<const char*>()) {
                        sc.payloadDevice = p["device"].as<String>();
                        sc.payloadAction = p["action"].as<String>();
                    }
                    cmdCount++;
                }
            }
        }
        http.end();
        return true;
    } else {
        Serial.printf("[Network] ❌ Ошибка получения pending команд. HTTP: %d\\n", httpCode);
        http.end();
        return false;
    }
}

bool Network::isConnected() { return wifiConnected && serverConnected; }
bool Network::hasPendingCommands() { return cmdCount > 0; }

ServerCommand Network::getNextCommand() {
    if (cmdCount == 0) return {0, "", "", 0, "", ""};
    ServerCommand cmd = commandQueue[cmdHead];
    cmdHead = (cmdHead + 1) % 10;
    cmdCount--;
    return cmd;
}

void Network::acknowledgeCommand(uint32_t id, bool success, const char* message) {
    HTTPClient http;
    String url = String("http://") + SERVER_HOST + ":" + SERVER_PORT + "/api/device/command/" + id + "/executed";
    Serial.printf("[Network] 📤 Подтверждение команды %d: %s\\n", id, url.c_str());

    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " DEVICE_TOKEN);
    http.setTimeout(3000);

    JsonDocument doc;
    doc["success"] = success;
    doc["message"] = message;

    String payload;
    serializeJson(doc, payload);

    int httpCode = http.POST(payload);
    if (httpCode == HTTP_CODE_OK) {


        Serial.printf("[Network] ✅ Команда %d успешно подтверждена.\\n", id);
    } else {
        Serial.printf("[Network] ❌ Ошибка подтверждения команды %d. HTTP: %d\\n", id, httpCode);
    }
    http.end();
}
bool Network::initTelemetryBuffer() {
    if (!LittleFS.begin()) {
        Serial.println("[Network] ❌ LittleFS mount failed, attempting to format...");
        if (!LittleFS.format()) {
            Serial.println("[Network] ❌ LittleFS format failed");
            return false;
        }
        if (!LittleFS.begin()) {
            Serial.println("[Network] ❌ LittleFS mount failed after format");
            return false;
        }
        Serial.println("[Network] ✅ LittleFS formatted and mounted");
    }
    // Load index
    File idxFile = LittleFS.open(TELEMETRY_IDX_FILE, "r");
    if (!idxFile) {
        // No index file, start from scratch
        telIndex.writeOffset = 0;
        telIndex.validCount = 0;
        Serial.println("[Network] 💾 Telemetry index file not found, starting fresh");
    } else {
        if (idxFile.size() == sizeof(telIndex)) {
            idxFile.readBytes((char*)&telIndex, sizeof(telIndex));
            Serial.printf("[Network] 💾 Loaded telemetry index: writeOffset=%u, validCount=%u\\n", telIndex.writeOffset, telIndex.validCount);
        } else {
            Serial.println("[Network] ⚠️ Index file size mismatch, resetting");
            telIndex.writeOffset = 0;
            telIndex.validCount = 0;
        }
        idxFile.close();
    }
    bufferInitialized = true;
    Serial.println("[Network] ✅ Telemetry buffer initialized");
    return true;
}

void Network::saveIndex() {
    File idxFile = LittleFS.open(TELEMETRY_IDX_FILE, "w");
    if (!idxFile) {
        Serial.println("[Network] ❌ Failed to open index file for writing");
        return;
    }
    idxFile.write((const uint8_t*)&telIndex, sizeof(telIndex));
    idxFile.close();
    Serial.printf("[Network] 💾 Saved telemetry index: writeOffset=%u, validCount=%u\\n", telIndex.writeOffset, telIndex.validCount);
}

void Network::storeTelemetry(uint32_t timestamp, const float values[5]) {
    if (!bufferInitialized) return;
    File dataFile = LittleFS.open(TELEMETRY_DATA_FILE, "a");
    if (!dataFile) {
        Serial.println("[Network] ❌ Failed to open telemetry data file for append");
        return;
    }
    // Write timestamp
    dataFile.write((const uint8_t*)&timestamp, sizeof(timestamp));
    // Write floats
    for (int i = 0; i < 5; i++) {
        dataFile.write((const uint8_t*)&values[i], sizeof(float));
    }
    dataFile.close();
    telIndex.writeOffset += sizeof(uint32_t) + 5 * sizeof(float);
    telIndex.validCount++;
    saveIndex();
    Serial.printf("[Network] 💾 Stored telemetry record at offset %u\\n", telIndex.writeOffset - (sizeof(uint32_t)+5*sizeof(float)));
}

void Network::flushTelemetryBuffer() {
    if (!bufferInitialized) return;
    File dataFile = LittleFS.open(TELEMETRY_DATA_FILE, "r");
    if (!dataFile) {
        Serial.println("[Network] ⚠️ No telemetry data file to flush");
        return;
    }
    size_t fileSize = dataFile.size();
    size_t recordSize = sizeof(uint32_t) + 5 * sizeof(float);
    size_t recordCount = fileSize / recordSize;
    if (recordCount == 0) {
        dataFile.close();
        Serial.println("[Network] ℹ️ Telemetry buffer empty");
        return;
    }
    Serial.printf("[Network] 🔄 Flushing %u telemetry records...\\n", recordCount);
    uint32_t timestamp;
    float values[5];
    size_t recordsSent = 0;
    while (dataFile.available() >= recordSize) {
        dataFile.readBytes((char*)&timestamp, sizeof(timestamp));
        for (int i = 0; i < 5; i++) {
            dataFile.readBytes((char*)&values[i], sizeof(float));
        }
        // Build payload and send
        String payload = buildTelemetryPayload(timestamp, values);
        if (!payload.isEmpty()) {
            HTTPClient http;
             String telemetryUrl = String("http://") + SERVER_HOST + ":" + SERVER_PORT + "/api/device/telemetry";
             Serial.printf("[Network] Telemetry URL: %s\\\\n", telemetryUrl.c_str());
            http.begin(telemetryUrl);
            http.addHeader("Content-Type", "application/json");
            http.addHeader("Authorization", "Bearer " DEVICE_TOKEN);
            int httpResponseCode = http.POST(payload);
            if (httpResponseCode > 0) {
                Serial.printf("[Network] 📤 Telemetry sent, HTTP code: %d\\n", httpResponseCode);
                recordsSent++;
            } else {
                Serial.printf("[Network] ❌ HTTP POST failed, error: %s\\n", http.errorToString(httpResponseCode).c_str());
            }
            http.end();
        } else {
            Serial.println("[Network] ⚠️ Failed to build telemetry payload");
        }
    }
    dataFile.close();
    // If we sent all records successfully, clear the file and reset index
    if (recordsSent == recordCount) {
        // Truncate file by opening for write and closing
        File truncateFile = LittleFS.open(TELEMETRY_DATA_FILE, "w");
        if (!truncateFile) {
            Serial.println("[Network] ❌ Failed to truncate telemetry data file");
        } else {
            truncateFile.close();
        }
        telIndex.writeOffset = 0;
        telIndex.validCount = 0;
        saveIndex();
        Serial.println("[Network] ✅ Telemetry buffer flushed and cleared");
    } else {
        Serial.println("[Network] ⚠️ Some records failed to send, keeping buffer for retry");
    }
}

String Network::buildTelemetryPayload(uint32_t timestamp, const float values[5]) {
    JsonDocument doc;
    doc["timestamp"] = timestamp;
    doc["room"] = values[0];
    doc["boiler"] = values[1];
    doc["floor"] = values[2];
    doc["accumulator"] = values[3];
    doc["outdoor"] = values[4];
    String payload;
    serializeJson(doc, payload);
    return payload;
}


// 🆕 НОВОЕ: Реализация OTA методов
bool Network::hasOtaUpdate() {
    return otaAvailable;
}

String Network::getOtaVersion() {
    return otaVersion;
}

String Network::getOtaUrl() {
    return otaUrl;
}

bool Network::performOTA() {
    if (!otaAvailable || otaUrl.isEmpty()) {
        Serial.println("[Network] ❌ OTA: Нет доступного обновления или URL пуст");
        return false;
    }

    Serial.printf("[Network] 🔄 OTA: Начинаем обновление до версии %s с %s\\n", otaVersion.c_str(), otaUrl.c_str());

    WiFiClient client;
    client.setTimeout(OTA_TIMEOUT_MS); // Таймаут задаём для клиента, а не для httpUpdate

    httpUpdate.rebootOnUpdate(true); // Правильное имя метода в ESP32 Core (без "set")

    // Начинаем процесс обновления
    t_httpUpdate_return ret = httpUpdate.update(client, otaUrl);

    switch (ret) {
        case HTTP_UPDATE_FAILED:
            Serial.printf("[Network] ❌ OTA Ошибка (%d): %s\\n", httpUpdate.getLastError(), httpUpdate.getLastErrorString().c_str());
            otaAvailable = false; // Сбрасываем флаг, чтобы не зациклить
            return false;
        case HTTP_UPDATE_NO_UPDATES:
            Serial.println("[Network] ℹ️ OTA: Обновление не требуется (версия совпадает)");
            otaAvailable = false;
            return false;
        case HTTP_UPDATE_OK:
            Serial.println("[Network] ✅ OTA: Обновление успешно! Перезагрузка...");
            return true; // ESP перезагрузится сам, но возвращаем true для логики
    }
    return false;
}




void Network::checkOtaUpdate() {
    if (millis() - lastOtaCheck < OTA_CHECK_INTERVAL_MS) return;
    lastOtaCheck = millis();
    if (!wifiConnected) return;
    HTTPClient http;
    http.begin(String("http://") + SERVER_HOST + ":" + SERVER_PORT + "/api/ota/check");
    http.addHeader("Authorization", "Bearer " DEVICE_TOKEN);
    int httpResponseCode = http.GET();
    if (httpResponseCode > 0) {
        String payload = http.getString();
        Serial.printf("[Network] OTA check response: %s\\n", payload.c_str());
        // parse JSON
        JsonDocument doc;
        DeserializationError error = deserializeJson(doc, payload);
        if (!error) {
            bool available = doc["ota_available"] | false;
            const char* version = doc["ota_version"] | "";
            const char* url = doc["ota_url"] | "";
            int size = doc["ota_size"] | 0;
            if (available && version && url) {
                otaAvailable = available;
                otaVersion = version;
                otaUrl = url;
                otaSize = size;
                Serial.printf("[Network] OTA update available: v%s (%d bytes) at %s\\n", otaVersion.c_str(), otaSize, otaUrl.c_str());
            } else {
                otaAvailable = false;
                Serial.println("[Network] OTA: No update available");
            }
        } else {
            Serial.printf("[Network] OTA JSON parse failed: %s\\n", error.c_str());
        }
    } else {
        Serial.printf("[Network] OTA check failed, error: %s\\n", http.errorToString(httpResponseCode).c_str());
    }
    http.end();
}

bool Network::sendSync(const String& payloadOverride) {
    String payload = payloadOverride;
    if (payload.isEmpty()) {
        payload = buildSyncPayload();
    }
    if (payload.isEmpty()) {
        Serial.println("[Network] ⚠️ Failed to build sync payload");
        return false;
    }
    String syncUrl = String("http://") + SERVER_HOST + ":" + SERVER_PORT + "/api/device/sync";
    Serial.printf("[Network] Sync URL: %s\\\\n", syncUrl.c_str());
    HTTPClient http;
    http.begin(syncUrl);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " DEVICE_TOKEN);
    int httpResponseCode = http.POST(payload);
    bool success = false;
    if (httpResponseCode > 0) {
        Serial.printf("[Network] 📤 Sync sent, HTTP code: %d\\\\n", httpResponseCode);
        success = true;
    } else {
        Serial.printf("[Network] ❌ HTTP POST failed, error: %s\\\\n", http.errorToString(httpResponseCode).c_str());
    }
    http.end();
    return success;
}
