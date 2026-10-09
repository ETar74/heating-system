#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// ===== Wi-Fi и Сервер =====
#define WIFI_SSID "Redmi123"
#define WIFI_PASSWORD "qwerty123456"
// IP облачного сервера (TimeWeb). Для локальной отладки укажите IP вашего ПК, например "192.168.1.10"
#define SERVER_HOST "129.101.119.233"
#define SERVER_PORT 3000
#define DEVICE_ID "ESP32-001"
#define FIRMWARE_VERSION "1.0.0"
// Токен устройства — ДОЛЖЕН совпадать с ESP32_TOKEN в .env на сервере.
// Сгенерировать на сервере: openssl rand -hex 32
#define DEVICE_TOKEN "3KBHDITsBwedBfxkzmNVb4J5zJWcaYycI/2XS/Ius/4="

// ===== Пины =====
#define PIN_ONE_WIRE       4
#define PIN_RELAY_BOILER   5
#define PIN_RELAY_FLOOR    18
#define PIN_RELAY_RADIATOR 19
#define PIN_RELAY_ELEC     21
#define PIN_BUTTON_CALIB   0
#define PIN_PHASE_SENSOR   34
#define NEXTION_RX         16
#define NEXTION_TX         17
#define NEXTION_BAUD       9600

// ===== Таймеры (мс) =====
#define SENSOR_READ_INTERVAL     5000
#define CONTROL_INTERVAL         1000
#define SERVER_HEARTBEAT         60000
#define NEXTION_UPDATE_INTERVAL  500
#define WIFI_CHECK_INTERVAL      10000

// ===== Network Retry / Backoff =====
#define NETWORK_BASE_RETRY_MS        5000      // Базовая задержка при ошибке (5 сек)
#define NETWORK_MAX_RETRY_MS         300000    // Максимальная задержка (5 минут)
#define NETWORK_RETRY_MULTIPLIER     2.0       // Множитель экспоненциального роста
#define NETWORK_MAX_RETRIES          12        // Макс. кол-во ретраев перед сбросом (5+10+20+40+80+160+300... ≈ 25 мин)

// ===== Роли датчиков =====
enum SensorRole {
    ROLE_ROOM = 0,
    ROLE_BOILER = 1,
    ROLE_FLOOR = 2,
    ROLE_ACCUMULATOR = 3,
    ROLE_OUTDOOR = 4
};
#define SENSOR_COUNT 5

// ===== Устройства =====
enum DeviceId {
    DEV_BOILER = 0,
    DEV_ELEC_BOILER = 1,
    DEV_FLOOR_PUMP = 2,
    DEV_RADIATOR_PUMP = 3
};
#define DEVICE_COUNT 4   // ← ДОБАВЛЕНО!

// ===== Расписание =====
#define SCHEDULE_SLOTS_PER_DEVICE 4

struct TimeSlot {
    uint8_t startH = 0;
    uint8_t startM = 0;
    uint8_t endH   = 0;
    uint8_t endM   = 0;
    bool    enabled = false;
};

struct DeviceSchedule {
    bool     enabled = false;
    TimeSlot slots[SCHEDULE_SLOTS_PER_DEVICE];
};

// ===== Задачи FreeRTOS =====
#define TASK_CONTROL_PRIORITY    5
#define TASK_SENSOR_PRIORITY     4
#define TASK_NEXTION_PRIORITY    3
#define TASK_NETWORK_PRIORITY    2

#define TASK_CONTROL_STACK       4096
#define TASK_SENSOR_STACK        4096
#define TASK_NEXTION_STACK       4096
#define TASK_NETWORK_STACK       8192

// ===== Критические пределы =====
#define CRITICAL_BOILER_TEMP_MAX      80.0
#define CRITICAL_ACCUMULATOR_TEMP_MAX 90.0

// ===== Пороги "горячего" для отображения потоков =====
#define FLOW_HOT_BOILER_MIN  40.0
#define FLOW_HOT_TA_MIN      35.0

// ===== Время и NTP =====
#define NTP_SERVER_1    "216.239.35.0"    // Google NTP (IP-адрес)
#define NTP_SERVER_2    "162.159.200.1"   // Cloudflare NTP (IP-адрес)
#define NTP_TIMEZONE    9
#define NTP_DST         0
#define NTP_SYNC_INTERVAL 21600000UL
#define NTP_TIMEOUT     10000

#define TIME_YEAR_MIN   2020
#define TIME_YEAR_MAX   2040

// ===== Структура настроек =====
struct SystemSettings {
    float boiler_threshold_on  = 55.0;
    float boiler_threshold_off = 65.0;
    float floor_threshold_on   = 24.0;
    float floor_threshold_off  = 26.0;
    float room_target_on       = 21.5;
    float room_target_off      = 22.5;
    float TA_target_on         = 64.0;
    float TA_target_off        = 66.0;
    uint16_t manual_timeout    = 30;
    char night_start[6] = "22:00";
    char night_end[6]   = "06:00";

    // Расписание по устройствам
    DeviceSchedule schedule[DEVICE_COUNT];
};

#define OTA_ENABLED true
#define OTA_TIMEOUT_MS 300000  // 5 минут таймаут на скачивание


#endif // CONFIG_H