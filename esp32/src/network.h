#ifndef NETWORK_H
#define NETWORK_H

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "config.h"

struct ServerCommand {
    uint32_t id;
    String type;
    String payloadKey;
    float payloadValue;
    String payloadString;    // ← ДОБАВЛЕНО: для строковых значений (night_start, night_end)
    String payloadDevice;
    String payloadAction;
};

class Network {
public:
    void begin();
    void update();
    bool syncWithServer();
    bool isConnected();

    bool hasPendingCommands();
    ServerCommand getNextCommand();
    void acknowledgeCommand(uint32_t id, bool success, const char* message);
    // Публичный таймер heartbeat для форсированного sync
    unsigned long lastHeartbeat = 0;

    // 🆕 НОВОЕ: Методы и переменные для OTA
    bool hasOtaUpdate();
    String getOtaVersion();
    String getOtaUrl();
    bool performOTA();

    bool otaAvailable = false;
    String otaVersion = "";
    String otaUrl = "";
    int otaSize = 0;

private:
    void connectWiFi();
    void checkWiFi();
    bool sendSync();
    bool fetchCommands();
    String buildSyncPayload();

    bool wifiConnected = false;
    bool serverConnected = false;
    unsigned long lastWifiCheck = 0;

    // ===== Network Retry / Backoff =====
    uint32_t retryDelay = 0;              // Задержка до следующей попытки (мс)
    uint8_t retryCount = 0;               // Кол-во ретраев в текущей серии


    ServerCommand commandQueue[10];
    uint8_t cmdCount = 0;
    uint8_t cmdHead = 0;
};

extern Network network;

#endif // NETWORK_H