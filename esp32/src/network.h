#ifndef NETWORK_H
#define NETWORK_H

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include <LITTLEFS.h>

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
    bool sendSync(const String& payloadOverride = String());
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

    // ===== Телеметрическая буферизация (LittleFS) =====
    static const uint32_t TELEMETRY_BUFFER_SIZE = 150 * 1024; // 150KB
    static const uint32_t TELEMETRY_RECORD_SIZE = sizeof(uint32_t) + 5 * sizeof(float); // timestamp + 5 floats
    static const uint32_t TELEMETRY_MAX_RECORDS = TELEMETRY_BUFFER_SIZE / TELEMETRY_RECORD_SIZE;
    const char* TELEMETRY_DATA_FILE = "/tel.bin";
    const char* TELEMETRY_IDX_FILE = "/tel.idx";
    struct TelemetryIndex {
        uint32_t writeOffset;
        uint32_t validCount;
    };
    TelemetryIndex telIndex;
    unsigned long lastBufferedTime = 0;
    const unsigned long BUFFER_INTERVAL_MS = 20 *  1000;// * 60 ; // 2 minutes
    unsigned long lastOtaCheck = 0;
    const unsigned long OTA_CHECK_INTERVAL_MS = 60 * 60 * 1000; // 1 hour
    bool bufferInitialized = false;

    bool initTelemetryBuffer();
    void saveIndex();
    void storeTelemetry(uint32_t timestamp, const float values[5]);
    void flushTelemetryBuffer();
    String buildTelemetryPayload(uint32_t timestamp, const float values[5]);
    void checkOtaUpdate();
};

extern Network network;
#endif // NETWORK_H
