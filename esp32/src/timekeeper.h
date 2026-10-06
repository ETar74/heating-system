#ifndef TIMEKEEPER_H
#define TIMEKEEPER_H

#include <Arduino.h>
#include <WiFiUdp.h>

struct DateTime {
    uint16_t year;
    uint8_t  month;
    uint8_t  day;
    uint8_t  hour;
    uint8_t  minute;
    uint8_t  second;
};

class TimeKeeper {
public:
    void begin();
    void update();
    
    DateTime getDateTime();
    uint32_t getUnixTimestamp();
    bool isSynced();
    
    // Возраст последней синхронизации
    unsigned long getLastSyncAge();    // в секундах
    float getLastSyncAgeHours();       // в часах (для UI)
    bool needsResync();                // true если прошло >= 6 часов
    
    // Синхронизация (публичная, вызывается из network.cpp)
    void syncNTP();
    
    // Ручная установка времени
    void setDateTime(const DateTime &dt);
    void adjustMinute(int8_t delta);
    void adjustHour(int8_t delta);
    void adjustDay(int8_t delta);
    void adjustMonth(int8_t delta);
    void adjustYear(int8_t delta);
    
    // Форматирование
    String formatTime();
    String formatDate();
    String formatDateTime();

private:
    uint32_t sendNTPPacket();
    uint32_t ntpOffset = 0;
    bool     synced = false;
    unsigned long lastSyncTime = 0;
    unsigned long lastNTPRequest = 0;
    
    WiFiUDP ntpUDP;
};

extern TimeKeeper timekeeper;

#endif // TIMEKEEPER_H