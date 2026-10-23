#include "ws_client.h"
#include "config.h"
#include "control.h"
#include "storage.h"

//  Инициализация глобального флага
bool wsJustConnected = false;

WSClient wsClient;

void WSClient::begin(const char* host, uint16_t port, const char* path, const char* token) {
    // Формируем заголовок авторизации: "Authorization: Bearer <token>"
    String authHeader = "Authorization: Bearer ";
    authHeader += token;
    
    webSocket.begin(host, port, path);
    webSocket.setExtraHeaders(authHeader.c_str());
    webSocket.onEvent([this](WStype_t type, uint8_t * payload, size_t length) {
        this->onEvent(type, payload, length);
    });
    webSocket.setReconnectInterval(3000); // Переподключение каждые 3 сек при обрыве
    
    Serial.println("[WS] Client initialized");
}

void WSClient::loop() {
    webSocket.loop();
}

bool WSClient::isConnected() {
    return connected;
}

void WSClient::onEvent(WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_DISCONNECTED:
            Serial.println("[WS] Disconnected");
            connected = false;
            break;
            
        case WStype_CONNECTED:
            Serial.printf("[WS] Connected to server\n");
            connected = true;
                // 🚀 НОВОЕ: При подключении WebSocket сразу проверяем pending команды
            Serial.println("[WS] Checking pending commands after reconnection...");
            // Здесь нужно вызвать функцию fetchCommands() из network.cpp
            // Но так как ws_client.cpp не имеет доступа к network.cpp, 
            // мы сделаем это через глобальный флаг
            extern bool wsJustConnected;
            wsJustConnected = true;
            break;
            
        case WStype_TEXT:
            {
                String msg = String((char*)payload);
                // Serial.printf("[WS] Received: %s\n", msg.c_str()); // Раскомментируй для отладки
                
                JsonDocument doc;
                DeserializationError error = deserializeJson(doc, msg);
                
                if (!error) {
                    String event = doc["event"] | "";
                    JsonObject data = doc["data"];
                    
                    if (event == "command:new") {
                        String command = data["command"] | "";
                        
                        if (command == "SET_SCHEDULE") {
                            Serial.println("[WS] 📋 Processing SET_SCHEDULE...");
                            
                            int deviceId = data["payload"]["deviceId"] | 0;
                            
                            // 🛑 FIX для ArduinoJson v7: проверяем тип через JsonVariant ПЕРЕД преобразованием
                            JsonVariant slotsVar = data["payload"]["slots"];
                            
                            if (slotsVar.is<JsonArray>() && slotsVar.size() == 4) {
                                JsonArray slots = slotsVar.as<JsonArray>();
                                
                                for (int i = 0; i < 4; i++) {
                                    control.settings.schedule[deviceId].slots[i].enabled = slots[i]["enabled"] | false;
                                    control.settings.schedule[deviceId].slots[i].startH  = slots[i]["startH"] | 0;
                                    control.settings.schedule[deviceId].slots[i].startM  = slots[i]["startM"] | 0;
                                    control.settings.schedule[deviceId].slots[i].endH    = slots[i]["endH"] | 0;
                                    control.settings.schedule[deviceId].slots[i].endM    = slots[i]["endM"] | 0;
                                }
                                
                                // Сохраняем в NVS
                                storage.saveSettings(control.settings);
                                Serial.println("[WS] ✅ Schedule applied and saved to NVS");
                                
                                // Отправляем подтверждение на сервер
                                JsonDocument ack;
                                ack["event"] = "device:command_ack";
                                ack["commandId"] = data["commandId"] | 0;
                                ack["success"] = true;
                                
                                String ackStr;
                                serializeJson(ack, ackStr);
                                webSocket.sendTXT(ackStr);
                                
                            } else {
                                Serial.println("[WS] ❌ Invalid slots array in payload");
                            }
                        }
                    }
                } else {
                    Serial.printf("[WS] JSON parse error: %s\n", error.c_str());
                }
            }
            break;
            
        case WStype_ERROR:
            Serial.println("[WS] Error");
            break;
    }
}