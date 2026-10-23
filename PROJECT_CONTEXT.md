# PROJECT_CONTEXT.md — ПАСПОРТ ПРОЕКТА

> Единый источник правды о системе. Передавать любой LLM/разработчику вместе с `.clinerules`.
> Версия документа: 1.0 | Дата: 2026-10-20 | Статус системы: рабочая, в активной разработке

---

## 1. ОБЩЕЕ ОПИСАНИЕ

Система мониторинга и управления отоплением частного дома. Управляет четырьмя контурами:
твердотопливный котёл, электрокотёл, тёплый пол, радиаторы.
Контроллер работает АВТОНОМНО при потере связи с сервером (локальное расписание + критические защиты).
Критичность: ВЫСОКАЯ — ошибка кода может привести к пожару, разморозке труб или потопу.

---

## 2. СТРУКТУРА РЕПОЗИТОРИЯ (MONOREPO)

heating-system/
├── esp32/ Прошивка контроллера (C++ / PlatformIO / FreeRTOS)
│ ├── platformio.ini Зависимости: ArduinoJson, OneWire, DallasTemperature, HTTPUpdate
│ └── src/
│ ├── main.cpp Точка входа, создание задач FreeRTOS
│ ├── config.h ЕДИНСТВЕННЫЙ источник #define: пины, пороги, тайминги, секреты
│ ├── control.h/cpp Реле, гистерезис, расписание, manual override, фазы, interlock, события
│ ├── sensors.h/cpp DS18B20 (1-Wire): опрос, валидация, калибровка, роли
│ ├── network.h/cpp WiFi, HTTP sync, очередь команд, OTA, LittleFS-буфер телеметрии
│ ├── nextion.h/cpp Дисплей Nextion 3.5" (UART), кэш отправки, клавиатура
│ ├── storage.h/cpp NVS (Preferences): настройки, состояния, magic-валидация
│ └── timekeeper.h/cpp NTP, RTC, расписание по времени
├── src/ Backend Node.js / Express (порт 3000)
│ ├── server.js Точка входа
│ ├── routes/ auth, device, commands, settings, telemetry, ota, users, events
│ ├── middleware/ auth (JWT), deviceAuth (Bearer token), rateLimit
│ ├── lib/ seed.js, online.js, alarms.js, notifications.js
│ └── bot.js Telegram-бот уведомлений (опционально)
├── frontend/ React + Vite (порт 5173): Login, Dashboard, Settings+OTA, Users, Events
├── prisma/schema.prisma Модели: User, Role, Device, Telemetry, Parameter, Event, Firmware, DeviceCache
├── docker-compose.yml Продакшн-деплой
├── .clinerules Правила для ИИ-агентов (конституция проекта)
├── ARCHITECTURE.md Диаграммы взаимодействий и потоки данных
└── TIMING_ANALYSIS.md Расчёт нагрузки и временных маржей


---

## 3. АППАРАТНАЯ ЧАСТЬ

| Элемент | Назначение | Примечание |
|---------|-----------|-----------|
| ESP32 (240 МГц, 2 ядра) | Контроллер | FreeRTOS, 4 задачи |
| Реле GPIO5 | Котёл (ТТ) | HIGH = ВКЛ |
| Реле GPIO21 | Электрокотёл | HIGH = ВКЛ |
| Реле GPIO18 | Насос тёплого пола | HIGH = ВКЛ |
| Реле GPIO19 | Насос радиаторов | HIGH = ВКЛ |
| DS18B20 ×4 (1-Wire) | Котёл, ТА, пол, комната | + outdoor (часто отсутствует, valid=0) |
| ADC GPIO34 | Датчик фаз L1/L2/L3 | Декодер диапазонов ADC, дебаунс 3 замера |
| Кнопка (INPUT_PULLUP) | Калибровка датчиков | |
| Nextion 3.5" | Локальный HMI | Serial2, 115200 baud, 9 страниц |

---

## 4. ЗАДАЧИ FREERTOS

| Задача | Приоритет | Стек | Интервал | Назначение |
|--------|-----------|------|----------|-----------|
| TaskControl | 5 | 8192 | 5 000 мс | Реле, гистерезис, расписание, фазы, interlock |
| TaskSensors | 3 | 4096 | 5 000 мс | Опрос DS18B20 (конвертация ~750 мс) |
| TaskNetwork | 2 | 8192 | heartbeat 60 c | Sync, команды, OTA, буфер телеметрии |
| TaskNextion | 1 | 8192 (минимум!) | 1 000 мс | Обновление дисплея, разбор команд UART |

Контроль стека: `uxTaskGetStackHighWaterMark(NULL)` (норма для TaskNextion: free > 6000).

---

## 5. ЛОГИКА УПРАВЛЕНИЯ

### Иерархия приоритетов (старший побеждает)
1. Emergency stop (все реле OFF на 5 минут)
2. Критические пороги (котёл > 95°C, ТА > 85°C) — хардкод, не изменяемы извне
3. Sensor fault: датчик невалиден => контур ВЫКЛ
4. Manual override (таймаут по умолчанию 30 мин, возврат в AUTO)
5. Расписание (4 устройства × 4 слота, гистерезис внутри активного слота)
6. Удалённые команды сервера

### Interlock (причины в логах)
SENSOR_FAULT | PHASE_LOSS | SCHEDULE_OFF | TEMP_DEMAND | HEATING | MANUAL

### Особенности контуров
- Тёплый пол: насос включается только если в ТА есть тепло (TA > FLOW_HOT_TA_MIN).
- Гистерезис: включение при t <= threshold_on, выключение при t >= threshold_off, между порогами состояние не меняется.

---

## 6. ПРОТОКОЛЫ ОБМЕНА

### ESP32 ↔ Server (HTTP/JSON, Authorization: Bearer DEVICE_TOKEN)
- `POST /api/device/sync` — телеметрия, состояния, события; в ответ: settings + schedule
- `GET /api/commands/pending` — очередь команд (SET_SCHEDULE, OTA_UPDATE, SET_*)
- `POST /api/commands/:id/executed` — подтверждение исполнения
- `GET /api/ota/check` — проверка обновлений (раз в час)
- `GET /api/ota/download/:id` — бинарник прошивки
- `POST /api/device/telemetry` — flush офлайн-буфера из LittleFS

### Frontend ↔ Server
REST + JWT (роли ADMIN / USER / DEVICE); 401 → logout через интерцептор Axios.

### ESP32 ↔ Nextion (UART)
- Исходящие команды завершаются `0xFF 0xFF 0xFF`.
- Входящие команды: `prints "имя",0` в событиях страниц/кнопок Nextion Editor.
- Префиксы команд: `pg0..pg8`, `key_*`, `sch_dev_N`, `sch_chk_N`, `sch_edit_N`, `sch_save`,
  `manual_*`, `inc_*/dec_*`, `save_set`, `time_*`, `cal_*`, `assign N M`, `emergency_stop`.
- Команды приходят СКЛЕЕННЫМИ ("pg2pg0") — разбор через `rxBuffer` + `extractCommand()`.

---

## 7. СТРАНИЦЫ NEXTION

| № | Назначение | Ключевые компоненты |
|---|-----------|---------------------|
| 0 | Главная | t_rval/t_fval/t_oval/t_aval/t_bval, pic_pf/pr/pb/pe, pic_flame, t_l1..l3, t_online |
| 1 | Схема | img_b, img_ta, img_p1..p3, img_f1..f3, ph_l1..l3, st_e, st_p1..p3 |
| 2 | Настройки | t_vbon/t_vbof/t_vfon/t_vfof/t_vron/t_vrof/t_vaon/t_vaof/t_vtm |
| 3 | Быстрый доступ | t_st_b/e/f/r, t_tm_b/e/f/r |
| 4 | Статус | (в разработке) |
| 5 | Калибровка | t_cnum, c_v0..4, c_t0..4 |
| 6 | Дата/время | t_date/t_time/t_year/.../t_minute, t_ntp |
| 7 | Расписание | t_cur_dev, t_s0..t_s3, c0..c3 (чекбоксы) |
| 8 | Клавиатура | t_input, t_template; команды key_0..9, key_colon, key_dash, key_back, key_clear, key_ok, key_cancel |

Правило: динамические тексты через UART — ТОЛЬКО ASCII. Кириллица — только статикой в Nextion Editor.

---

## 8. БЕЗОПАСНОСТЬ И FAIL-SAFE

1. Старт: все реле принудительно LOW ДО чтения NVS.
2. NVS: чтение только при magic number 0xDEADBEEF, иначе safe defaults (всё OFF).
3. Запись в NVS только при изменении (ресурс flash ~100k циклов).
4. Перед решением о нагреве — `sensors.isSensorValid(role)`; невалиден => контур OFF.
5. Критические пороги хардкодом в config.h, не доступны из веба/NVS.
6. Потеря связи: автономная работа по локальному расписанию; телеметрия копится в LittleFS.
7. Аутентификация: JWT (пользователи), статический DEVICE_TOKEN (контроллер).
8. Дефолтный admin/admin123 из seed.js подлежит смене в продакшене.

---

## 9. КОНФИГУРАЦИЯ И СЕКРЕТЫ

- Единственный источник `#define` — `esp32/src/config.h` (пины, пороги, тайминги, SSID, токен).
- Backend-секреты — `.env` (JWT_SECRET, ESP32_TOKEN, DATABASE_URL, CORS_ORIGINS).
- Дублирование `#define` в других заголовках ЗАПРЕЩЕНО (исторический баг network.h).
- Секреты не дублировать в документации, комментариях и логах.

---

## 10. ТАЙМИНГИ

| Операция | Интервал | Худшее время | Маржа |
|----------|----------|-------------|-------|
| Цикл управления реле | 5 000 мс | ~120 мс | 97% |
| Опрос датчиков | 5 000 мс | ~800 мс | 84% |
| Обновление дисплея | 1 000 мс | ~60 мс | 94% |
| Heartbeat/sync | 60 000 мс (backoff 5c…5мин при отказе) | ~5 000 мс | 50% |
| Реакция на перегрев/обрыв датчика | — | < 1 000 мс | критично |
| Реакция на кнопку дисплея | — | < 1 000 мс | ОК |
| Реакция на веб-команду | — | до 60 c (heartbeat) | приемлемо |

---

## 11. КАТАЛОГ ГРАБЛЕЙ (УРОКИ ПРОШЛЫХ ОТЛАДОК — НЕ ВОЗВРАЩАТЬ)

1. Stack overflow TaskNextion из-за цепочек String; лечится стеком 8192 + char[]/snprintf/sscanf.
2. Зависание Nextion: переполнение UART-буфера при пачке команд => потеря 0xFF-терминаторов;
   лечится delay(100–300 мс) после `page N` и delay(5–10 мс) между командами отрисовки.
3. UTF-8/кириллица через UART вешает парсер Nextion — только ASCII в динамике.
4. `DeviceEvent` с `const char*` = dangling pointer; хранить char[16]/char[64].
5. `continue` при пустой команде в цикле `while(hasCommand())` = infinite loop; использовать `break`.
6. `hasCommand()` обязан учитывать rxBuffer, иначе команды теряются/залипают.
7. Веб шлёт deviceId 1..4, массивы ESP32 0..3 — нормализовать (`devId--`).
8. После SET_SCHEDULE из сети обязателен `nextion.resetCache()` при открытом экране 7.
9. `resetCache()` с 50+ присваиваниями String опасен для стека; сбрасывать только числовые поля кэша.
10. Сигнатуры .h/.cpp обязаны совпадать; публичны: currentPage, scheduleDevice, resetCache().

---

## 12. СОГЛАШЕНИЯ КОДА

- Правки минимальны, по одной за раз; после правки — сборка `pio run`.
- Функции для вставки показывать ЦЕЛИКОМ.
- Пометки правок: `// FIX-YYYY-MM-DD: причина`.
- Горячие пути задач: char[] + snprintf/sscanf, без String-цепочек.
- HTTP-клиент всегда с `setTimeout()`; никаких блокировок в TaskControl.
- Логи: префиксы `[Control] [Sensors] [Network] [Nextion] [TaskNextion] [Storage] [TimeKeeper]`.

---

## 13. СБОРКА И ДИАГНОСТИКА
Сборка: pio run
Прошивка: pio run -t upload
Лог: pio device monitor -b 115200
Стек задачи: uxTaskGetStackHighWaterMark(NULL)
Backend: node server.js | Frontend: npm run dev (frontend/)


---

## 14. СЛОВАРЬ

ТА — тепловой аккумулятор | MO — manual override | Interlock — цепочка защитных проверок
before/after-логи — диагностика задач | rxBuffer — буфер склеенных команд UART
Magic number — сигнатура целостности NVS (0xDEADBEEF) | Fail-Safe — все реле OFF при любом отказе
