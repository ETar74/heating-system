#ifndef WS_CLIENT_H
#define WS_CLIENT_H

#include <WebSocketsClient.h>
#include <ArduinoJson.h>

// 🚀 Глобальный флаг: WebSocket только что подключился
extern bool wsJustConnected;

class WSClient {
public:
    void begin(const char* host, uint16_t port, const char* path, const char* token);
    void loop();
    bool isConnected();

private:
    WebSocketsClient webSocket;
    bool connected = false;
    void onEvent(WStype_t type, uint8_t * payload, size_t length);
};

extern WSClient wsClient;
#endif