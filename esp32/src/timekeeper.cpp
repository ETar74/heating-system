#include "timekeeper.h"
#include <WiFi.h>   
#include "config.h"

TimeKeeper timekeeper;

// ===== NTP пакеты =====
static const int NTP_PACKET_SIZE = 48;
static byte ntpBuffer[NTP_PACKET_SIZE];

void TimeKeeper::begin() {
    // Открываем порт НЕМЕДЛЕННО. Теперь syncNTP() можно вызывать в любой момент.
    ntpUDP.begin(123); 
    Serial.println("[TimeKeeper] Initialized (UDP port 123 opened, waiting for WiFi)");
}

void TimeKeeper::update() {
    // 1. Если время ЕЩЁ НЕ синхронизировано, пробуем получить его при наличии Wi-Fi
    if (!synced && WiFi.status() == WL_CONNECTED) {
        // Не спамим запросами, пробуем раз в 10 секунд при старте, пока не получится
        static unsigned long lastAttempt = 0;
        if (millis() - lastAttempt > 10000) {
            Serial.println("[TimeKeeper] 🔄 Attempting initial NTP sync (not synced yet)...");
            syncNTP();
            lastAttempt = millis();
        }
    } 
    // 2. Если время УЖЕ синхронизировано, проверяем, не прошло ли 6 часов
    else if (synced && (millis() - lastSyncTime >= NTP_SYNC_INTERVAL)) {
        Serial.println("[TimeKeeper] 🔄 6 hours passed, attempting re-sync...");
        syncNTP();
    }
}

void TimeKeeper::syncNTP() {
    Serial.println("[TimeKeeper] >>> syncNTP() ЗАПУЩЕНА <<<"); // 1. Точка входа
    
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[TimeKeeper] ABORT: WiFi not connected");
        return;
    }
    Serial.println("[TimeKeeper] Step 1: WiFi OK");

    if (synced && (millis() - lastSyncTime < NTP_SYNC_INTERVAL)) {
        unsigned long hours = (millis() - lastSyncTime) / 3600000;
        Serial.printf("[TimeKeeper] ABORT: Already synced %lu hours ago\n", hours);
        return;
    }
    Serial.println("[TimeKeeper] Step 2: 6-hour interval check OK");

    // ИСПРАВЛЕНИЕ: Пропускаем проверку, если это самый первый запрос (lastNTPRequest == 0)
    if (lastNTPRequest != 0 && (millis() - lastNTPRequest < 30000)) {
        Serial.printf("[TimeKeeper] ABORT: Rate limit active (wait 30s). millis: %lu, last: %lu\n", 
                      millis(), lastNTPRequest);
        return;
    }
    Serial.println("[TimeKeeper] Step 3: Rate limit check OK");
    
    lastNTPRequest = millis(); // Запоминаем время попытки
    
    Serial.println("[TimeKeeper] Syncing with NTP...");
    Serial.printf("[TimeKeeper] WiFi IP: %s\n", WiFi.localIP().toString().c_str());
    
    ntpUDP.begin(123);
    Serial.println("[TimeKeeper] UDP port 123 opened");
    
    Serial.printf("[TimeKeeper] Trying server 1: %s\n", NTP_SERVER_1);
    uint32_t ts = sendNTPPacket();
    
    if (ts == 0) {
        delay(100);
        Serial.printf("[TimeKeeper] Trying server 2: %s\n", NTP_SERVER_2);
        ts = sendNTPPacket();
    }
    
    ntpUDP.stop();
    Serial.println("[TimeKeeper] UDP port closed");
    
    if (ts > 0) {
        uint32_t currentMillis = millis() / 1000;
        ntpOffset = ts - currentMillis;
        synced = true;
        lastSyncTime = millis();
        
        DateTime dt = getDateTime();
        Serial.printf("[TimeKeeper] >>> SUCCESS! NTP synced! Time: %04d-%02d-%02d %02d:%02d:%02d <<<\n",
                      dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    } else {
        Serial.println("[TimeKeeper] FAILED: No response from NTP servers");
    }
}

uint32_t TimeKeeper::sendNTPPacket() {
    memset(ntpBuffer, 0, NTP_PACKET_SIZE);
    ntpBuffer[0] = 0b11100011;  // LI, Version, Mode
    ntpBuffer[1] = 0;           // Stratum
    ntpBuffer[2] = 6;           // Polling interval
    ntpBuffer[3] = 0xEC;        // Peer clock precision
    
    ntpUDP.beginPacket(NTP_SERVER_1, 123);
    ntpUDP.write(ntpBuffer, NTP_PACKET_SIZE);
    ntpUDP.endPacket();
    
    // Ждём ответ
    unsigned long startWait = millis();
    while (millis() - startWait < NTP_TIMEOUT) {
        int size = ntpUDP.parsePacket();
        if (size >= NTP_PACKET_SIZE) {
            ntpUDP.read(ntpBuffer, NTP_PACKET_SIZE);
            
            uint32_t secsSince1900 = 
                (uint32_t)ntpBuffer[40] << 24 |
                (uint32_t)ntpBuffer[41] << 16 |
                (uint32_t)ntpBuffer[42] << 8  |
                (uint32_t)ntpBuffer[43];
            
            const uint32_t SEVENTY_YEARS = 2208988800UL;
            uint32_t epoch = secsSince1900 - SEVENTY_YEARS;
            
            // Применяем часовой пояс
            epoch += (uint32_t)NTP_TIMEZONE * 3600;
            if (NTP_DST) epoch += 3600;
            
            return epoch;
        }
        delay(100);
    }
    return 0;
}

DateTime TimeKeeper::getDateTime() {
    DateTime dt;
    uint32_t unixTime;
    
    if (synced) {
        unixTime = (millis() / 1000) + ntpOffset;
    } else {
        // Если не синхронизировано — возвращаем время с последнего ручного ввода
        // или 01.01.2020 00:00
        unixTime = 1577836800UL;  // 2020-01-01 00:00:00 UTC
    }
    
    // Конвертация Unix time → дата/время (алгоритм без библиотек)
    uint32_t seconds = unixTime % 60;
    uint32_t minutes = (unixTime / 60) % 60;
    uint32_t hours   = (unixTime / 3600) % 24;
    
    uint32_t days = unixTime / 86400;
    uint16_t year = 1970;
    uint8_t  month = 1;
    uint8_t  day = 1;
    
    while (true) {
        uint16_t daysInYear = ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) ? 366 : 365;
        if (days < daysInYear) break;
        days -= daysInYear;
        year++;
    }
    
    uint8_t daysInMonth[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        daysInMonth[1] = 29;
    }
    
    for (month = 1; month <= 12; month++) {
        if (days < daysInMonth[month - 1]) break;
        days -= daysInMonth[month - 1];
    }
    day = days + 1;
    
    dt.year   = year;
    dt.month  = month;
    dt.day    = day;
    dt.hour   = hours;
    dt.minute = minutes;
    dt.second = seconds;
    
    return dt;
}

uint32_t TimeKeeper::getUnixTimestamp() {
    if (synced) return (millis() / 1000) + ntpOffset;
    return 1577836800UL;
}

bool TimeKeeper::isSynced() { return synced; }

unsigned long TimeKeeper::getLastSyncAge() {
    return (millis() - lastSyncTime) / 1000;
}

// ===== Ручная установка времени =====
void TimeKeeper::setDateTime(const DateTime &dt) {
    // Конвертация даты/времени → Unix timestamp
    uint16_t y = dt.year;
    uint8_t  m = dt.month;
    uint8_t  d = dt.day;
    
    // Алгоритм конвертации
    if (m <= 2) { y--; m += 12; }
    uint32_t days = 365UL * y + y/4 - y/100 + y/400 + (153 * (m - 3) + 2) / 5 + d - 719469;
    uint32_t unixTime = days * 86400UL + dt.hour * 3600UL + dt.minute * 60UL + dt.second;
    
    // Вычисляем новое смещение (без вычитания часового пояса!)
    uint32_t currentMillis = millis() / 1000;
    ntpOffset = unixTime - currentMillis;
    synced = true;
    lastSyncTime = millis();
    
    Serial.printf("[TimeKeeper] Manual time set: %04d-%02d-%02d %02d:%02d\n",
                  dt.year, dt.month, dt.day, dt.hour, dt.minute);
}

void TimeKeeper::adjustMinute(int8_t delta) {
    DateTime dt = getDateTime();
    int newMin = (int)dt.minute + delta;
    if (newMin < 0) { newMin = 59; adjustHour(-1); }
    if (newMin > 59) { newMin = 0; adjustHour(1); }
    dt.minute = newMin;
    setDateTime(dt);
}

void TimeKeeper::adjustHour(int8_t delta) {
    DateTime dt = getDateTime();
    int newHour = (int)dt.hour + delta;
    if (newHour < 0) { newHour = 23; adjustDay(-1); }
    if (newHour > 23) { newHour = 0; adjustDay(1); }
    dt.hour = newHour;
    setDateTime(dt);
}

void TimeKeeper::adjustDay(int8_t delta) {
    DateTime dt = getDateTime();
    int newDay = (int)dt.day + delta;
    
    uint8_t daysInMonth[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if ((dt.year % 4 == 0 && dt.year % 100 != 0) || (dt.year % 400 == 0)) {
        daysInMonth[1] = 29;
    }
    int maxDay = daysInMonth[dt.month - 1];
    
    if (newDay < 1) { newDay = maxDay; adjustMonth(-1); }
    if (newDay > maxDay) { newDay = 1; adjustMonth(1); }
    dt.day = newDay;
    setDateTime(dt);
}

void TimeKeeper::adjustMonth(int8_t delta) {
    DateTime dt = getDateTime();
    int newMonth = (int)dt.month + delta;
    if (newMonth < 1) { newMonth = 12; adjustYear(-1); }
    if (newMonth > 12) { newMonth = 1; adjustYear(1); }
    dt.month = newMonth;
    setDateTime(dt);
}

void TimeKeeper::adjustYear(int8_t delta) {
    DateTime dt = getDateTime();
    int newYear = (int)dt.year + delta;
    if (newYear < TIME_YEAR_MIN) newYear = TIME_YEAR_MIN;
    if (newYear > TIME_YEAR_MAX) newYear = TIME_YEAR_MAX;
    dt.year = newYear;
    setDateTime(dt);
}

// ===== Форматирование =====
String TimeKeeper::formatTime() {
    DateTime dt = getDateTime();
    char buf[8];
    snprintf(buf, sizeof(buf), "%02d:%02d", dt.hour, dt.minute);
    return String(buf);
}

String TimeKeeper::formatDate() {
    DateTime dt = getDateTime();
    char buf[12];
    snprintf(buf, sizeof(buf), "%02d.%02d.%04d", dt.day, dt.month, dt.year);
    return String(buf);
}

String TimeKeeper::formatDateTime() {
    DateTime dt = getDateTime();
    char buf[20];
    snprintf(buf, sizeof(buf), "%02d.%02d.%04d %02d:%02d", 
             dt.day, dt.month, dt.year, dt.hour, dt.minute);
    return String(buf);
}

float TimeKeeper::getLastSyncAgeHours() {
    if (!synced) return 999.0;  // никогда не синхронизировалось
    return (float)(millis() - lastSyncTime) / 3600000.0;
}

bool TimeKeeper::needsResync() {
    return getLastSyncAgeHours() >= 6.0;
}