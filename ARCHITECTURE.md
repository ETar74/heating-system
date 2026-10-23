📁 ФАЙЛОВАЯ СТРУКТУРА ПРОЕКТА
heating-system/
│
├── 📁 frontend/                    # React + Vite
│   ├── 📁 src/
│   │   ├── 📁 pages/
│   │   │   ├── Login.jsx          # Авторизация
│   │   │   ├── Dashboard.jsx      # Главный экран
│   │   │   ├── Settings.jsx       # Настройки + расписание
│   │   │   ├── ScheduleSection.jsx # Компонент расписания
│   │   │   └── OTA.jsx            # OTA обновления
│   │   ├── api.js                 # Axios + интерцепторы
│   │   ├── websocket.js           # WebSocket клиент
│   │   └── App.jsx                # Роутинг
│   └── package.json
│
├── 📁 src/                         # Backend Node.js/Express
│   ├── 📁 routes/
│   │   ├── auth.js                # Аутентификация
│   │   ├── device.js              # Синхронизация ESP32
│   │   ├── schedule.js            # Управление расписанием
│   │   ├── commands.js            # Очередь команд
│   │   ├── settings.js            # Параметры системы
│   │   ├── ota.js                 # OTA обновления
│   │   └── telemetry.js           # История температур
│   ├── 📁 middleware/
│   │   ├── auth.js                # JWT проверка
│   │   └── deviceAuth.js          # Токен ESP32
│   ├── 📁 lib/
│   │   ├── online.js              # Статус устройств
│   │   └── alarms.js              # Обработка аварий
│   ├── websocket.js               # Socket.IO сервер
│   └── bot.js                     # Telegram бот
│
├── 📁 esp32/                       # Прошивка контроллера
│   ├── 📁 src/
│   │   ├── main.cpp               # Точка входа, FreeRTOS
│   │   ├── config.h               # Пины, константы
│   │   ├── network.cpp/h          # WiFi, HTTP, OTA
│   │   ├── websocket_client.cpp/h # WebSocket клиент
│   │   ├── sensors.cpp/h          # DS18B20 (1-Wire)
│   │   ├── control.cpp/h          # Управление реле
│   │   ├── storage.cpp/h          # NVS хранилище
│   │   ├── nextion.cpp/h          # Дисплей Nextion
│   │   └── timekeeper.cpp/h       # NTP, часы
│   └── platformio.ini
│
├── 📁 prisma/
│   └── schema.prisma              # Схема БД
│
├── server.js                      # Главный файл backend
├── docker-compose.yml             # Docker конфигурация
├── package.json                   # Зависимости backend
└── .env                           # Секреты и токены

🔄 СХЕМА ОБМЕНА ДАННЫМИ

┌─────────────────────────────────────────────────────────────────────┐
│                         ПОЛЬЗОВАТЕЛЬ                                 │
│                       (Веб-браузер)                                  │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ WebSocket + REST API
                             │
                    ┌────────▼────────┐
                    │   FRONTEND      │
                    │   (React)       │
                    │   порт 5173     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              │ HTTP/REST    │ WebSocket    │ HTTP/REST
              │ + JWT        │ (Socket.IO)  │ + JWT
              │              │              │
              │              │              │
┌─────────────▼──────────────▼──────────────▼─────────────┐
│                    BACKEND (Node.js)                     │
│                    Express + Socket.IO                   │
│                    порт 3000                              │
│                                                          │
│  • Аутентификация (JWT)                                  │
│  • Очередь команд для ESP32                              │
│  • Валидация данных (Zod)                                │
│  • Ретрансляция WebSocket событий                        │
│  • Telegram уведомления                                  │
└──────┬────────────────────────────────────┬─────────────┘
       │                                    │
       │ HTTP + Bearer Token                │ WebSocket
       │ (polling каждые 10 сек)            │ (мгновенно)
       │                                    │
       │                                    │
┌──────▼────────────────────────────────────▼─────────────┐
│                  БАЗА ДАННЫХ (PostgreSQL)                │
│                  Prisma ORM                              │
│                                                          │
│  • Пользователи (User, Role)                            │
│  • Телеметрия (Telemetry)                               │
│  • Команды (Command - очередь)                          │
│  • Настройки (Parameter)                                │
│  • Расписание (Schedule)                                │
│  • Прошивки (Firmware)                                  │
│  • События (Event)                                      │
└──────────────────────────────────────────────────────────┘
       ▲                                    ▲
       │                                    │
       │ HTTP + Device Token                │ WebSocket
       │                                    │
       │                                    │
┌──────┴────────────────────────────────────┴─────────────┐
│              КОНТРОЛЛЕР (ESP32)                          │
│              FreeRTOS + Arduino Framework                │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │ TaskControl (приоритет 5)                       │    │
│  │ • Управление реле                               │    │
│  │ • Расписание                                    │    │
│  │ • Критические пороги                            │    │
│  │ • Ручное управление                             │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │ TaskSensors (приоритет 3)                       │    │
│  │ • Опрос DS18B20 (1-Wire)                       │    │
│  │ • Валидация данных                              │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │ TaskNetwork (приоритет 2)                       │    │
│  │ • WiFi подключение                              │    │
│  │ • HTTP синхронизация                            │    │
│  │ • WebSocket клиент                              │    │
│  │ • OTA обновления                                │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │ TaskDisplay (приоритет 1)                       │    │
│  │ • Обновление Nextion (UART)                    │    │
│  │ • Обработка кнопок                              │    │
│  └─────────────────────────────────────────────────┘    │
└──────┬────────────────────────────────────┬─────────────┘
       │                                    │
       │ UART 115200                        │ 1-Wire
       │                                    │
       │                                    │
┌──────▼──────────┐              ┌──────────▼──────────┐
│   ДИСПЛЕЙ       │              │    ДАТЧИКИ          │
│   Nextion 3.5"  │              │    DS18B20 × 4      │
│   8 страниц     │              │                     │
│                 │              │  • Котёл            │
│  • Главная      │              │  • ТА               │
│  • Схема        │              │  • Пол              │
│  • Настройки    │              │  • Комната          │
│  • Расписание   │              │                     │
│  • Клавиатура   │              └─────────────────────┘
└─────────────────┘


📊 ПОТОКИ ДАННЫХ (КРАТКО)

heating-system/
│
├── 📁 frontend/src/
│   │
│   ├── 📄 api.js ─────────────────────────────────────────┐
│   │   │                                                   │
│   │   ├── 📤 POST /api/auth/login ──────► backend/auth.js │ (JWT token)
│   │   ├── 📤 GET  /api/telemetry ──────► backend/telemetry.js (раз в 10 сек)
│   │   ├── 📤 PUT  /api/settings ───────► backend/settings.js (по запросу)
│   │   ├── 📤 POST /api/device/schedule/save ─► backend/schedule.js (расписание)
│   │   ├── 📤 POST /api/ota/upload ─────► backend/ota.js (файл .bin)
│   │   └── 📤 GET  /api/commands/pending ► backend/commands.js (опционально)
│   │
│   ├── 📄 websocket.js ───────────────────────────────────┐
│   │   │                                                   │
│   │   ├── 📤 connect(socket.io) ────────► backend/websocket.js (при логине)
│   │   ├── 📥 "telemetry:update" ◄────── backend/websocket.js (мгновенно)
│   │   ├── 📥 "schedule:updated" ◄────── backend/websocket.js (мгновенно)
│   │   ├── 📥 "device:status"    ◄────── backend/websocket.js (мгновенно)
│   │   └── 📥 "alarm"            ◄────── backend/websocket.js (аварии)
│   │
│   ├── 📄 pages/Dashboard.jsx
│   │   ├── 📥 Использует данные от api.js + websocket.js
│   │   └── 📤 Отправляет команды через api.js
│   │
│   ├── 📄 pages/ScheduleSection.jsx
│   │   ├── 📤 PUT /api/device/schedule/save (через api.js)
│   │   └── 📥 Получает обновления через websocket.js
│   │
│   └── 📄 pages/OTA.jsx
│       └── 📤 POST /api/ota/upload (файл прошивки через api.js)
│
│
├── 📁 src/ (backend)
│   │
│   ├── 📄 server.js ──────────────────────────────────────┐
│   │   ├── 📥 HTTP requests от frontend (порт 3000)
│   │   ├── 📥 HTTP requests от ESP32 (порт 3000)
│   │   └── 📤 Маршрутизирует запросы к routes/*.js
│   │
│   ├── 📄 websocket.js
│   │   ├── 📥 "device:telemetry" ◄────── esp32/websocket_client.cpp
│   │   ├── 📤 "telemetry:update" ──────► frontend/websocket.js (всем пользователям)
│   │   ├── 📤 "command:new" ───────────► esp32/websocket_client.cpp (мгновенно)
│   │   └── 📤 "schedule:updated" ──────► frontend/websocket.js (всем)
│   │
│   ├── 📁 routes/
│   │   │
│   │   ├── 📄 auth.js
│   │   │   ├── 📥 POST /auth/login ◄──── frontend/api.js
│   │   │   └── 📤 JWT token ───────────► frontend/api.js
│   │   │
│   │   ├── 📄 device.js
│   │   │   ├── 📥 POST /device/sync ◄─── esp32/network.cpp (каждые 10 сек)
│   │   │   ├── 📤 Настройки ────────────► esp32/network.cpp (в ответе)
│   │   │   ├── 📥 POST /device/command/:id/executed ◄─ esp32 (подтверждение)
│   │   │   └── 📤 В prisma.command (обновляет status='executed')
│   │   │
│   │   ├── 📄 schedule.js
│   │   │   ├── 📥 POST /schedule/save ◄─ frontend/ScheduleSection.jsx
│   │   │   ├── 📤 Создает команду SET_SCHEDULE в prisma.command
│   │   │   └── 📤 Отправляет через websocket.js (мгновенно)
│   │   │
│   │   ├── 📄 commands.js
│   │   │   ├── 📥 GET /commands/pending ◄─ esp32/network.cpp (каждые 5 сек)
│   │   │   └── 📤 JSON с командой ──────► esp32/network.cpp
│   │   │
│   │   ├── 📄 settings.js
│   │   │   ├── 📥 PUT /settings ◄─────── frontend/api.js
│   │   │   └── 📤 Создает команду SET_PARAMETER в prisma.command
│   │   │
│   │   ├── 📄 ota.js
│   │   │   ├── 📥 POST /ota/upload ◄──── frontend/OTA.jsx
│   │   │   ├── 📤 Сохраняет .bin файл на диск
│   │   │   ├── 📥 GET /ota/download/:id ◄─ esp32/network.cpp (при OTA)
│   │   │   └── 📤 Бинарные данные .bin ──► esp32/network.cpp
│   │   │
│   │   └── 📄 telemetry.js
│   │       ├── 📥 GET /telemetry/latest ◄─ frontend/api.js
│   │       ├── 📥 GET /telemetry/history ◄─ frontend/api.js
│   │       └── 📤 JSON телеметрии ──────► frontend/api.js
│   │
│   ├── 📁 lib/
│   │   │
│   │   ├── 📄 online.js
│   │   │   ├── 📥 Проверяет lastSeen в prisma.device
│   │   │   └── 📤 Статус online/offline ─► frontend/websocket.js
│   │   │
│   │   └── 📄 alarms.js
│   │       ├── 📥 Анализирует teleметрию на пороги
│   │       ├── 📤 Создает prisma.event (ALARM)
│   │       ├── 📤 Отправляет через websocket.js ─► frontend
│   │       └── 📤 Отправляет через bot.js ─► Telegram
│   │
│   └── 📄 bot.js (Telegram)
│       ├── 📥 События от alarms.js
│       └── 📤 HTTP POST api.telegram.org (уведомления)
│
│
├── 📁 prisma/
│   │
│   └── 📄 schema.prisma ──────────────────────────────────┐
│       ├── 📥 Запросы от backend/routes/*.js (через Prisma Client)
│       │   ├── User, Role (аутентификация)
│       │   ├── Device (статус ESP32, lastSeen)
│       │   ├── Telemetry (история температур)
│       │   ├── Command (очередь команд для ESP32)
│       │   ├── Parameter (настройки системы)
│       │   ├── Schedule (расписание)
│       │   ├── Firmware (OTA прошивки)
│       │   └── Event (журнал событий)
│       └── 📤 Результаты запросов ──────► backend/routes/*.js
│
│
└── 📁 esp32/src/
    │
    ├── 📄 main.cpp (точка входа)
    │   ├── 📤 Создает задачи FreeRTOS:
    │   │   ├── TaskControl (приоритет 5)
    │   │   ├── TaskSensors (приоритет 3)
    │   │   ├── TaskNetwork (приоритет 2)
    │   │   └── TaskDisplay (приоритет 1)
    │   └── 📥 Данные от всех задач через глобальные объекты
    │
    ├── 📄 control.cpp ────────────────────────────────────┐
    │   ├── 📤 Текущие состояния реле ────► nextion.cpp (каждую 1 сек)
    │   ├── 📤 События (ALARM/INFO) ─────► network.cpp (для сервера)
    │   ├── 📥 Настройки из storage.cpp (NVS)
    │   ├── 📥 Расписание из storage.cpp (NVS)
    │   ├── 📥 Команды SET_SCHEDULE ────── network.cpp
    │   ├── 📥 Команды SET_PARAMETER ──── network.cpp
    │   └── 📤 Управляющие сигналы ──────► РЕЛЕ (GPIO)
    │
    ├── 📄 sensors.cpp ────────────────────────────────────┐
    │   ├── 📤 Запрос конвертации ───────► DS18B20 (1-Wire)
    │   ├── 📥 Температура (4 датчика) ◄── DS18B20 (1-Wire)
    │   ├── 📤 SensorData struct ────────► control.cpp (для логики)
    │   ├── 📤 SensorData struct ────────► network.cpp (для телеметрии)
    │   └── 📤 SensorData struct ────────► nextion.cpp (для дисплея)
    │
    ├── 📄 network.cpp ────────────────────────────────────┐
    │   │
    │   ├── 📤 WiFi подключение ────────► Роутер (802.11)
    │   │
    │   ├── 📤 HTTP POST /api/device/sync ──► backend/device.js (10 сек)
    │   │   ├── Body: телеметрия + события + состояния
    │   │   └── Header: Bearer DEVICE_TOKEN
    │   │
    │   ├── 📥 HTTP ответ ◄─────────────── backend/device.js
    │   │   └── Body: настройки + команды
    │   │
    │   ├── 📤 HTTP GET /api/commands/pending ► backend/commands.js (5 сек)
    │   ├── 📥 JSON с командами ◄──────── backend/commands.js
    │   │   ├── SET_SCHEDULE → control.cpp
    │   │   ├── SET_PARAMETER → storage.cpp
    │   │   ├── OTA_UPDATE → performOTA()
    │   │   └── SET_DEVICE → control.cpp
    │   │
    │   ├── 📤 HTTP POST /api/commands/:id/executed ► backend/device.js
    │   │   └── Подтверждение выполнения команды
    │   │
    │   ├── 📤 HTTP GET /api/ota/download/:id ► backend/ota.js (при OTA)
    │   ├── 📥 Бинарный .bin файл ◄─────── backend/ota.js
    │   │   └── Запись во Flash через HTTPUpdate
    │   │
    │   └── 📥 Команды от websocket_client.cpp (мгновенно)
    │
    ├── 📄 websocket_client.cpp ───────────────────────────┐
    │   ├── 📤 WebSocket connect ────────► backend/websocket.js
    │   │   └── Header: Bearer DEVICE_TOKEN
    │   │
    │   ├── 📤 "device:telemetry" ───────► backend/websocket.js (реал-тайм)
    │   ├── 📤 "device:status"    ───────► backend/websocket.js (реал-тайм)
    │   │
    │   ├── 📥 "command:new" ◄──────────── backend/websocket.js (мгновенно)
    │   │   ├── SET_SCHEDULE → control.cpp (обход очереди!)
    │   │   └── SET_PARAMETER → storage.cpp
    │   │
    │   └── 📤 "device:command_ack" ─────► backend/websocket.js
    │
    ├── 📄 nextion.cpp ────────────────────────────────────┐
    │   │
    │   ├── 📤 UART TX (GPIO17) ────────► Nextion дисплей
    │   │   ├── Обновление текстов (температуры)
    │   │   ├── Обновление картинок (насосы, потоки)
    │   │   ├── Обновление цветов (активность)
    │   │   └── Команды перехода страниц
    │   │
    │   └── 📥 UART RX (GPIO16) ◄─────── Nextion дисплей
    │       ├── pg0..pg8 (смена страницы)
    │       ├── key_0..key_9, key_ok (клавиатура)
    │       ├── manual_* (ручное управление)
    │       ├── sch_dev_*, sch_chk_*, sch_edit_* (расписание)
    │       ├── inc_*/dec_* (настройки)
    │       ├── cal_scan, cal_save (калибровка)
    │       ├── time_* (дата/время)
    │       └── emergency_stop
    │
    ├── 📄 storage.cpp ────────────────────────────────────┐
    │   ├── 📤 Чтение/запись ────────────► NVS (Flash память)
    │   │   ├── SystemSettings (настройки)
    │   │   ├── DeviceStates (состояния реле)
    │   │   ├── DeviceSchedule (расписание)
    │   │   └── SensorAddresses (адреса DS18B20)
    │   │
    │   ├── 📤 Данные настроек ──────────► control.cpp (при старте)
    │   └── 📤 Состояния реле ───────────► control.cpp (при старте)
    │
    └── 📄 timekeeper.cpp ─────────────────────────────────┐
        ├── 📤 UDP NTP запрос ──────────► pool.ntp.org:123
        ├── 📥 NTP ответ ◄─────────────── pool.ntp.org:123
        ├── 📤 Текущее время ───────────► control.cpp (для расписания)
        └── 📤 Текущее время ───────────► nextion.cpp (для дисплея)
        


# Архитектура веб-интерфейса расписания (Schedule Web Interface)

## Вкладка "Настройки" (Settings Tab)

### Цель
Позволить пользователю задавать расписание включения/выключения устройств через веб-интерфейс:
- Электрокотел (ЭК)
- Газовый котел (ГК)
- Насос теплого пола (НТП)
- Насос радиATORов (НР)

### Структура данных

#### DeviceSchedule (в NVS/БД)
```cpp
struct DeviceSchedule {
    bool enabled;           // Master switch: включать расписание вообще
    TimeSlot slots[4];      // До 4 слотів на устройство
};

struct TimeSlot {
    bool enabled;           // Slot включен
    uint8_t startH, startM;
    uint8_t endH, endM;
};
```

#### Веб-хранилище (Prisma DB / JSON)
```json
{
  "devices": {
    "1": {
      "enabled": true,
      "slots": [
        { "enabled": true, "start": "08:00", "end": "20:00" }
      ]
    }
  }
}
```

### Компоненты интерфейса

#### 1. Settings.jsx (React component)
```jsx
<Tabs>
  <Tab label="Schedule">
    {devices.map(device => (
      <DeviceScheduleCard key={device.id} device={device} />
    ))}
  </Tab>
</Tabs>
```

#### 2. DeviceScheduleCard — для каждого устройства
```html
<div className="schedule-card">
  <h4>{deviceName}</h4>
  <Label className="switch">
    <input type="checkbox" checked={schedule.enabled} onChange={toggleMasterSchedule} />
    {schedule.enabled ? 'Вкл' : 'Выкл'}
  </Label>
  <div>Слот 1: Время: --:-- - --:--</div>
  <div>Слот 2: Время: --:-- - --:--</div>
  <div>Слот 3: Время: --:-- - --:--</div>
  <div>Слот 4: Время: --:-- - --:--</div>
  <Button onClick={addNewSlot}>Добавить слот</Button>
</div>
```

#### 3. API эндпоинты
- GET /api/device/settings - получить расписание
- PUT /api/device/settings - обновить расписание

### Flow: Изменение → Применение

1. User открывает вкладку "Настройки → Расписание"
2. Видит текущее расписание из БД
3. Включает/выключает мастер-выключатель для устройства
4. Добавляет/редактирует слоты времени
5. Нажимает "Сохранить"
6. Frontend отправляет PUT /api/device/settings
7. Backend сохраняет в БД и отправляет сообщение на ESP32
8. ESP32 парсит JSON и обновляет `SystemSettings.schedule`
9. Перезапуск цикла `evaluateAllRelays()` с новыми значениями

### Интеграция с firmware

#### В network.cpp (обработка входящих)
```cpp
void handleSchedule(JsonObject doc) {
    uint8_t device = doc["device"];
    settings.schedule[device].enabled = doc["enabled"];
    for (uint8_t s = 0; s < SCHEDULE_SLOTS_PER_DEVICE; s++) {
        auto& slot = settings.schedule[device].slots[s];
        slot.enabled = doc["slots"][s]["enabled"];
        slot.startH = doc["slots"][s]["startH"];
        slot.startM = doc["slots"][s]["startM"];
        slot.endH   = doc["slots"][s]["endH"];
        slot.endM   = doc["slots"][s]["endM"];
    }
    storage.saveSettings(settings);
}
```

#### В control_logic.cpp (уже готово)
Функция `isScheduleActive()` теперь работает по принципу:
- Только `slot.enabled` (master `sched.enabled` убран — как в GitHub HEAD)
- Пустые слоты (`00:00-00:00`) пропускаются

### UI/UX детали

#### Валидация
- Start time < End time (или через полночь: start > end)
- Минимум 1 минута间隔 между start и end
- Максимум 4 слота на устройство

#### Состояния слотов
- **ВКЛ** — слот активен, устройство будет включено при попадании времени
- **ВЫКЛ** — слот игнорируется

### Обратная совместимость
- Если в БД нет поля `schedule.enabled` — старый код работает (только slot.enabled)
- Экспорт/импорт настроек в формате JSON для резервного копирования

### Roadmap
1. Создание структуры БД и API эндпоинтов
2. Базовый UI: мастер-включатель + добавление 1 слота
3. Модальные окна редактирования слотов
4. 4 слота на устройство, Drag & Drop интерфейс
5. Тестирование на реальном железе, релиз
﻿
