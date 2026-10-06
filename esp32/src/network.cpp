#include "network.h"
#include "timekeeper.h"
#include "sensors.h"
#include "control.h"
#include <HTTPUpdate.h>  // 🆕 НОВОЕ: Библиотека для OTA обновлений

Network network;

void Network::begin() {
    connectWiFi();
    lastHeartbeat = 0;
    lastWifiCheck = 0;
    cmdCount = 0;
    cmdHead = 0;
}

void Network::connectWiFi() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    Serial.printf("[Network] Подключение к Wi-Fi: '%s'...\n", WIFI_SSID);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        wifiConnected = true;
        Serial.printf("\n[Network] ✅ Wi-Fi подключен! IP адрес ESP32: %s\n", WiFi.localIP().toString().c_str());
        
        // 🆕 ВСТАВИТЬ СЮДА ТЕСТ TCP СОЕДИНЕНИЯ:
        WiFiClient testClient;
        Serial.printf("[Network] 🧪 Тест прямого TCP-соединения с %s:%d ...\n", SERVER_HOST, SERVER_PORT);
        if (testClient.connect(SERVER_HOST, SERVER_PORT, 3000)) {
            Serial.println("[Network] ✅ TCP СОЕДИНЕНИЕ УСПЕШНО! Порт открыт, сеть работает.");
            testClient.stop();
        } else {
            Serial.println("[Network] ❌ TCP СОЕДИНЕНИЕ НЕВОЗМОЖНО! Телефон/сеть блокирует порт 3000.");
        }
        
        //needNtpSync = true;
    } else {
        wifiConnected = false;
        Serial.println("\n[Network] ❌ ОШИБКА: Не удалось подключиться к Wi-Fi.");
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
    if (!wifiConnected) {
        // Если Wi-Fi отключен, проверяем периодически (не используем backoff для Wi-Fi)
        if (millis() - lastWifiCheck >= WIFI_CHECK_INTERVAL) {
            checkWiFi();
        }
        return;
    }

    // Если подключены к Wi-Fi, но нет соединения с сервером, используем backoff
    if (!serverConnected) {
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
                // Ошибка - увеличиваем задержку экспоненциально
                retryCount++;
                if (retryCount >= NETWORK_MAX_RETRIES) {
                    retryCount = NETWORK_MAX_RETRIES;
                }
                // Экспоненциальное увеличение с пределом
                retryDelay = (uint32_t)(NETWORK_BASE_RETRY_MS * pow(NETWORK_RETRY_MULTIPLIER, retryCount));
                if (retryDelay > NETWORK_MAX_RETRY_MS) {
                    retryDelay = NETWORK_MAX_RETRY_MS;
                }
                Serial.printf("[Network] Backoff: попытка %d, следующая через %lu мс\n", 
                              retryCount, retryDelay);
            }
        }
        return;
    }

    // Если подключены к серверу - обычный heartbeat
    if (millis() - lastHeartbeat >= SERVER_HEARTBEAT) {
        lastHeartbeat = millis();
        if (!syncWithServer()) {
            // Сервер перестал отвечать - переключаемся в режим backoff
            serverConnected = false;
            retryDelay = NETWORK_BASE_RETRY_MS;
            retryCount = 0;
        }
    }
}

bool Network::syncWithServer() {
    if (!wifiConnected) return false;
    Serial.println("[Network] 🔄 Начало синхронизации с сервером...");
    
    if (sendSync()) {
        serverConnected = true;
        // Команды теперь забираются прямо внутри sendSync() из ответа сервера!
        // Отдельный вызов fetchCommands() здесь больше не нужен.
        return true;
    } else {
        serverConnected = false;
        Serial.println("[Network] ❌ Синхронизация не удалась. Повтор через 60 сек.");
        return false;
    }
}

bool Network::sendSync() {
    WiFiClient client;
    HTTPClient http;

    String url = String("http://") + SERVER_HOST + ":" + SERVER_PORT + "/api/device/sync";
    Serial.printf("[Network] ????? POST request to: %s\n", url.c_str());

    http.begin(client, url);
    http.setReuse(false);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " DEVICE_TOKEN);
    http.setTimeout(10000);  // Увеличим таймаут до 10 сек
    http.setFollowRedirects(HTTPC_DISABLE_FOLLOW_REDIRECTS);
    
    String payload = buildSyncPayload();
    
    Serial.printf("[Network] 📦 Размер payload: %d байт\n", payload.length());
    
    int httpCode = http.POST(payload);
    Serial.printf("[Network] 📡 HTTP код ответа: %d\n", httpCode);
    
    bool isSuccess = false;

    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        Serial.printf("[Network] ✅ Синхронизация успешна (HTTP 200). Ответ: %.200s\n", response.c_str());
        
        JsonDocument doc;
        DeserializationError error = deserializeJson(doc, response);
        
        if (!error) {
            // === КОМАНДЫ ===
            if (doc["commands"].is<JsonArray>()) {
                JsonArray commands = doc["commands"].as<JsonArray>();
                for (JsonObject cmd : commands) {
                    if (cmdCount < 10) {
                        ServerCommand &sc = commandQueue[(cmdHead + cmdCount) % 10];
                        sc.id = cmd["id"];
                        sc.type = cmd["type"].as<String>();
                        
                        JsonObject p = cmd["payload"];
                        sc.payloadString = "";
                        
                        if (p["key"].is<const char*>()) {
                            sc.payloadKey = p["key"].as<String>();
                            if (p["value"].is<float>() || p["value"].is<int>()) {
                                sc.payloadValue = p["value"];
                            } else if (p["value"].is<const char*>()) {
                                sc.payloadString = p["value"].as<String>();
                                sc.payloadValue = 0;
                            }
                        }
                        if (p["device"].is<const char*>()) {
                            sc.payloadDevice = p["device"].as<String>();
                            sc.payloadAction = p["action"].as<String>();
                        }
                        cmdCount++;
                        Serial.printf("[Network] 📥 Команда: ID=%d, Type=%s\n", sc.id, sc.type.c_str());
                    }
                }
            }
            
            // === OTA ===
            if (doc["ota"].is<JsonObject>()) {
                JsonObject ota = doc["ota"];
                if (ota["available"].as<bool>()) {
                    otaAvailable = true;
                    otaVersion = ota["version"].as<String>();
                    otaUrl = ota["url"].as<String>();
                    otaSize = ota["size"];
                    Serial.printf("[Network] 📥 OTA доступна: v%s (%d bytes)\n", otaVersion.c_str(), otaSize);
                } else {
                    otaAvailable = false;
                }
            } else {
                otaAvailable = false;
            }
            isSuccess = true;
        } else {
            Serial.printf("[Network] ❌ Ошибка парсинга JSON: %s\n", error.c_str());
        }
    } else {
        Serial.printf("[Network] ❌ HTTP ошибка. Код: %d, Описание: %s\n", 
                      httpCode, http.errorToString(httpCode).c_str());
    }
    
    http.end();
    client.stop();  // 🆕 Явно закрываем TCP-соединение
    
    return isSuccess;
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
    settings["boiler_temp_target"]        = s.boiler_threshold_on; // Для совместимости с фронтендом
    
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

// Эта функция оставлена для совместимости, но теперь используется редко
bool Network::fetchCommands() {
    HTTPClient http;
    // ИСПРАВЛЕН URL: убрано слово "device"
    String url = String("http://") + SERVER_HOST + ":" + SERVER_PORT + "/api/commands/pending";
    Serial.printf("[Network] 📥 Запрос команд (GET): %s\n", url.c_str());
    
    http.begin(url);
    http.addHeader("Authorization", "Bearer " DEVICE_TOKEN);
    http.setTimeout(5000);
    int httpCode = http.GET();
    
    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        Serial.printf("[Network] ✅ Команды получены. Ответ: %s\n", response.c_str());
        
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
        Serial.printf("[Network] ❌ Ошибка получения команд. HTTP код: %d\n", httpCode);
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
    Serial.printf("[Network] 📤 Подтверждение команды %d: %s\n", id, url.c_str());
    
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
        Serial.printf("[Network] ✅ Команда %d успешно подтверждена.\n", id);
    } else {
        Serial.printf("[Network] ❌ Ошибка подтверждения команды %d. HTTP: %d\n", id, httpCode);
    }
    http.end();
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

    Serial.printf("[Network] 🔄 OTA: Начинаем обновление до версии %s с %s\n", otaVersion.c_str(), otaUrl.c_str());
    
    WiFiClient client;
    client.setTimeout(OTA_TIMEOUT_MS); // Таймаут задаём для клиента, а не для httpUpdate

    httpUpdate.rebootOnUpdate(true); // Правильное имя метода в ESP32 Core (без "set")

    // Начинаем процесс обновления
    t_httpUpdate_return ret = httpUpdate.update(client, otaUrl);

    switch (ret) {
        case HTTP_UPDATE_FAILED:
            Serial.printf("[Network] ❌ OTA Ошибка (%d): %s\n", httpUpdate.getLastError(), httpUpdate.getLastErrorString().c_str());
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