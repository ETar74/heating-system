### USER
Выдай файл API.md

### ASSISTANT
# 📄 API.md — Полная документация API системы отопления

**Создайте файл:** `D:\KotelAI\heating-system\API.md`

**Содержимое:**

```markdown
# 🔌 API Documentation — Heating System

**Base URL:** `http://localhost:3000/api`  
**Версия:** 1.2  
**Дата:** 2026-06-30  
**Описание:** Система управления отоплением на базе ESP32 с блокировкой изменений при потере связи с устройством.

---

## 📋 Содержание

1. [Авторизация](#-авторизация)
2. [Пользователи](#-пользователи)
3. [Настройки](#-настройки)
4. [Телеметрия](#-телеметрия)
5. [События](#-события)
6. [Команды](#-команды)
7. [Устройства](#-устройства)
8. [ESP32 Sync](#-esp32-sync)
9. [Коды ошибок](#-коды-ошибок)
10. [Примеры использования](#-примеры-использования)

---

## 🔐 Авторизация

### POST /auth/login

**Описание:** Вход в систему, получение JWT токена.

**Тело запроса:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Ответ (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "role": "ADMIN"
  }
}
```

**Пример (PowerShell):**
```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"username":"admin","password":"admin123"}'
$token = $response.token
```

---

### POST /auth/logout

**Описание:** Выход из системы.

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

---

### GET /auth/me

**Описание:** Получить информацию о текущем пользователе.

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200 OK):**
```json
{
  "id": 1,
  "username": "admin",
  "role": "ADMIN"
}
```

---

## 👥 Пользователи

**Требуемая роль:** ADMIN

### GET /users

**Описание:** Получить список всех пользователей.

**Ответ (200 OK):**
```json
[
  {
    "id": 1,
    "username": "admin",
    "role": "ADMIN",
    "telegramId": "123456789",
    "createdAt": "2026-06-20T10:00:00.000Z"
  }
]
```

---

### POST /users

**Описание:** Создать нового пользователя.

**Тело запроса:**
```json
{
  "username": "newuser",
  "password": "password123",
  "role": "VIEWER",
  "telegramId": "987654321"
}
```

**Параметры:**
| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| `username` | string | ✅ | Логин |
| `password` | string | ✅ | Пароль |
| `role` | string | ✅ | "ADMIN", "OPERATOR", "VIEWER" |
| `telegramId` | string | ❌ | Telegram ID |

**Ответ (201 Created):**
```json
{
  "id": 3,
  "username": "newuser",
  "role": "VIEWER"
}
```

---

### PUT /users/:id

**Описание:** Обновить пользователя.

**Тело запроса (все поля опциональны):**
```json
{
  "username": "newname",
  "password": "newpassword",
  "role": "OPERATOR",
  "telegramId": "123456789"
}
```

---

### DELETE /users/:id

**Описание:** Удалить пользователя.

**Ответ (200 OK):**
```json
{
  "message": "User deleted"
}
```

---

## ⚙️ Настройки

### 🔒 Блокировка при офлайн ESP32

**Важно!** Изменение настроек через `PUT /api/settings/:key` и `PUT /api/settings` **заблокировано**, если ESP32 не выходит на связь более 2 минут.

**Логика работы:**
| Состояние ESP32 | Разрешено менять настройки? |
|-----------------|------------------------------|
| 🟢 Онлайн (sync < 2 мин) | ✅ Да |
| 🔴 Офлайн (sync > 2 мин) | ❌ Нет (HTTP 423) |
| ⚠️ Связь восстановлена | ✅ Да (после получения sync от ESP32) |

---

### GET /settings

**Описание:** Получить все настройки системы.

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200 OK):**
```json
[
  {
    "key": "room_temp_target",
    "value": "22.0",
    "updatedAt": "2026-06-30T14:35:10.801Z"
  },
  {
    "key": "room_temp_threshold_on",
    "value": "21.5",
    "updatedAt": "2026-06-30T14:35:10.801Z"
  }
]
```

**Доступные ключи настроек:**

| Ключ | Описание | Тип | По умолчанию |
|------|----------|-----|--------------|
| `room_temp_target` | Целевая температура помещения | °C | 22.0 |
| `room_temp_threshold_on` | Порог включения отопления | °C | 21.5 |
| `room_temp_threshold_off` | Порог выключения отопления | °C | 22.5 |
| `boiler_temp_target` | Целевая температура котла | °C | 60.0 |
| `boiler_temp_threshold_on` | Порог включения котла | °C | 55.0 |
| `boiler_temp_threshold_off` | Порог выключения котла | °C | 65.0 |
| `floor_temp_target` | Целевая температура тёплого пола | °C | 25.0 |
| `floor_temp_threshold_on` | Порог включения насоса ТП | °C | 24.0 |
| `floor_temp_threshold_off` | Порог выключения насоса ТП | °C | 26.0 |
| `accumulator_temp_target` | Целевая температура ТА | °C | 65.0 |
| `accumulator_temp_threshold_on` | Порог включения ЭК | °C | 60.0 |
| `accumulator_temp_threshold_off` | Порог выключения ЭК | °C | 70.0 |
| `night_start` | Начало ночного режима | HH:MM | 22:00 |
| `night_end` | Конец ночного режима | HH:MM | 06:00 |
| `manual_timeout` | Таймаут ручного управления | сек | 30 |

---

### GET /settings/can-edit

**Описание:** Проверить, можно ли менять настройки (ESP32 онлайн?).

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200 OK):**
```json
{
  "canEdit": true,
  "deviceOnline": true,
  "lastSync": "2026-06-30T14:35:10.801Z",
  "message": "Устройство подключено. Изменение настроек разрешено."
}
```

**Ответ при офлайн ESP32:**
```json
{
  "canEdit": false,
  "deviceOnline": false,
  "lastSync": "2026-06-30T14:30:00.000Z",
  "message": "Устройство недоступно. Изменение настроек заблокировано."
}
```

---

### PUT /api/settings/:key

**Описание:** Изменить одну настройку.

**Требуемая роль:** ADMIN, OPERATOR  
**Блокировка:** 🔒 Если ESP32 офлайн — вернётся HTTP 423

**Заголовки:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "value": "23.5"
}
```

**Ответ (200 OK):**
```json
{
  "success": true,
  "commandId": 5,
  "message": "Command queued for ESP32"
}
```

**Ответ при офлайн ESP32 (423 Locked):**
```json
{
  "error": "Device offline",
  "message": "Изменение настроек заблокировано: устройство ESP32 недоступно. Дождитесь восстановления связи."
}
```

**Пример (PowerShell):**
```powershell
$headers = @{Authorization="Bearer $token"}
$body = @{value="23.5"} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/settings/room_temp_target" `
  -Method PUT -Headers $headers -ContentType "application/json" -Body $body
```

---

### PUT /api/settings

**Описание:** Массовое изменение настроек.

**Требуемая роль:** ADMIN, OPERATOR  
**Блокировка:** 🔒 Если ESP32 офлайн — вернётся HTTP 423

**Тело запроса:**
```json
{
  "parameters": [
    {"key": "room_temp_target", "value": "22.0"},
    {"key": "boiler_temp_target", "value": "60.0"}
  ]
}
```

---

## 📊 Телеметрия

### GET /telemetry/latest

**Описание:** Получить последние показания всех датчиков.

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200 OK):**
```json
{
  "room_temp": {
    "value": 22.3,
    "timestamp": "2026-06-30T14:35:10.801Z"
  },
  "boiler_temp": {
    "value": 58.5,
    "timestamp": "2026-06-30T14:35:10.801Z"
  },
  "floor_temp": {
    "value": 24.8,
    "timestamp": "2026-06-30T14:35:10.801Z"
  },
  "accumulator_temp": {
    "value": 65.0,
    "timestamp": "2026-06-30T14:35:10.801Z"
  },
  "outdoor_temp": {
    "value": -5.2,
    "timestamp": "2026-06-30T14:35:10.801Z"
  },
  "phases": {
    "value": {
      "L1": true,
      "L2": true,
      "L3": true
    },
    "timestamp": "2026-06-30T14:35:10.801Z"
  }
}
```

**Параметры телеметрии:**

| Ключ | Описание | Единица |
|------|----------|---------|
| `room_temp` | Температура помещения | °C |
| `boiler_temp` | Температура котла | °C |
| `floor_temp` | Температура тёплого пола | °C |
| `accumulator_temp` | Температура теплоаккумулятора | °C |
| `outdoor_temp` | Температура улицы | °C |
| `phases` | Состояние фаз (L1, L2, L3) | bool |

**Примечание:** Значение `-127` означает неисправность датчика.

---

### GET /telemetry/history

**Описание:** Получить историю показаний.

**Query параметры:**
- `parameter` (string) — параметр (например, `room_temp`)
- `hours` (number) — период в часах (по умолчанию 24)

**Пример:**
```
GET /api/telemetry/history?parameter=room_temp&hours=48
```

---

## 📋 События

### GET /events

**Описание:** Получить журнал событий.

**Query параметры:**
- `limit` (number) — количество (по умолчанию 100)

**Ответ (200 OK):**
```json
[
  {
    "id": 1,
    "eventType": "INFO",
    "message": "User admin logged in",
    "createdAt": "2026-06-30T14:35:10.801Z"
  }
]
```

**Типы событий:**
- `INFO` — информационное
- `WARNING` — предупреждение
- `ERROR` — ошибка
- `ALARM` — аварийная ситуация

---

## 🎮 Команды

### POST /commands

**Описание:** Отправить команду устройству.

**Требуемая роль:** ADMIN, OPERATOR

**Тело запроса:**
```json
{
  "command": "boiler_on",
  "payload": {}
}
```

**Доступные команды:**
- `boiler_on` / `boiler_off`
- `floor_pump_on` / `floor_pump_off`
- `radiator_pump_on` / `radiator_pump_off`

---

### GET /commands/pending

**Описание:** Получить команды в очереди (для ESP32).

**Ответ (200 OK):**
```json
[
  {
    "id": 5,
    "type": "SET_SETTING",
    "payload": {
      "key": "room_temp_target",
      "value": 23.0
    },
    "createdAt": 1735000000
  }
]
```

---

## 📡 Устройства

### GET /device/status

**Описание:** Получить статус устройства.

**Ответ (200 OK):**
```json
{
  "name": "ESP32-001",
  "online": true,
  "lastSeen": "2026-06-30T14:35:10.801Z",
  "deviceStatus": {
    "boiler": "on",
    "elec_boiler": "off",
    "floor_pump": "on",
    "radiator_pump": "on"
  },
  "uptime": 3600,
  "firmware": "1.0.0",
  "lastSync": "2026-06-30T14:35:10.801Z"
}
```

**Поле `online`:**
- `true` — последний sync менее 2 минут назад
- `false` — связь потеряна

---

### POST /device/telemetry

**Описание:** Отправить телеметрию от устройства (старый формат).

**Тело запроса:**
```json
{
  "serialNumber": "ESP32-001",
  "data": {
    "room_temp": 22.3,
    "boiler_temp": 58.5
  }
}
```

---

### POST /device/command/:id/executed

**Описание:** Подтвердить выполнение команды.

**Тело запроса:**
```json
{
  "success": true,
  "message": "Command executed successfully"
}
```

---

## 🔄 ESP32 Sync

### POST /device/sync

**Описание:** Полная синхронизация данных от ESP32.

**Важно:** При получении sync сервер:
1. ✅ Обновляет кэш `device_cache`
2. ✅ **Сохраняет настройки в таблицу `parameters`** (синхронизация БД)
3. ✅ Сохраняет телеметрию в историю
4. ✅ Обновляет статус устройства
5. ✅ Сохраняет события
6. ✅ Отдаёт команды из очереди

**Тело запроса:**
```json
{
  "deviceId": "ESP32-001",
  "timestamp": 1735000000,
  "uptime": 3600,
  "firmware": "1.0.0",
  "settings": {
    "room_temp_target": 22.0,
    "room_temp_threshold_on": 21.5,
    "room_temp_threshold_off": 22.5,
    "boiler_temp_target": 60.0,
    "boiler_temp_threshold_on": 55.0,
    "boiler_temp_threshold_off": 65.0,
    "floor_temp_target": 25.0,
    "floor_temp_threshold_on": 24.0,
    "floor_temp_threshold_off": 26.0,
    "accumulator_temp_target": 65.0,
    "accumulator_temp_threshold_on": 60.0,
    "accumulator_temp_threshold_off": 70.0,
    "night_start": "22:00",
    "night_end": "06:00",
    "manual_timeout": 30
  },
  "telemetry": {
    "room_temp": 22.3,
    "boiler_temp": 58.5,
    "floor_temp": 24.8,
    "accumulator_temp": 65.0,
    "outdoor_temp": -5.2
  },
  "device_status": {
    "boiler": "on",
    "elec_boiler": "off",
    "floor_pump": "on",
    "radiator_pump": "on"
  },
  "phases": {
    "L1": true,
    "L2": true,
    "L3": true
  },
  "events": [
    {
      "id": 1,
      "timestamp": 1735000000,
      "type": "INFO",
      "message": "Boiler turned ON"
    }
  ]
}
```

**Ответ (200 OK):**
```json
{
  "success": true,
  "serverTime": 1735000001,
  "commands": [
    {
      "id": 5,
      "type": "SET_SETTING",
      "payload": {
        "key": "room_temp_target",
        "value": 23.0
      },
      "createdAt": 1735000000
    }
  ]
}
```

---

## 🚫 Коды ошибок

| Код | Описание | Когда возвращается |
|-----|----------|---------------------|
| 400 | Bad Request | Неверный формат запроса |
| 401 | Unauthorized | Токен отсутствует или невалиден |
| 403 | Forbidden | Недостаточно прав |
| 404 | Not Found | Ресурс не найден |
| **423** | **Locked** | **ESP32 офлайн — изменение настроек заблокировано** |
| 500 | Internal Server Error | Внутренняя ошибка сервера |

---

## 🔑 Аутентификация

Все защищённые эндпоинты требуют заголовок:
```
Authorization: Bearer <token>
```

**Срок действия токена:** 24 часа

---

## 🎯 Быстрая шпаргалка

| Действие | Метод | URL | Блокировка |
|----------|-------|-----|------------|
| Войти | POST | /auth/login | ❌ |
| Получить настройки | GET | /settings | ❌ |
| **Проверить возможность редактирования** | **GET** | **/settings/can-edit** | ❌ |
| **Изменить настройку** | **PUT** | **/settings/:key** | **🔒 Если ESP32 офлайн** |
| **Массовое изменение** | **PUT** | **/settings** | **🔒 Если ESP32 офлайн** |
| Получить телеметрию | GET | /telemetry/latest | ❌ |
| История телеметрии | GET | /telemetry/history | ❌ |
| Получить события | GET | /events | ❌ |
| Получить пользователей | GET | /users | ❌ |
| Создать пользователя | POST | /users | ❌ |
| Отправить команду | POST | /commands | ❌ |
| Очередь команд | GET | /commands/pending | ❌ |
| Статус устройства | GET | /device/status | ❌ |
| **Синхронизация ESP32** | **POST** | **/device/sync** | ❌ |
| Подтвердить команду | POST | /device/command/:id/executed | ❌ |

---

## 💡 Примеры использования

### PowerShell

```powershell
# 1. Получить токен
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"username":"admin","password":"admin123"}'
$token = $response.token

# 2. Проверить, можно ли менять настройки
$headers = @{Authorization="Bearer $token"}
$canEdit = Invoke-RestMethod -Uri "http://localhost:3000/api/settings/can-edit" -Headers $headers
$canEdit | ConvertTo-Json

# 3. Получить настройки
Invoke-RestMethod -Uri "http://localhost:3000/api/settings" -Headers $headers

# 4. Изменить настройку (если ESP32 онлайн)
$body = @{value="23.5"} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/settings/room_temp_target" `
  -Method PUT -Headers $headers -ContentType "application/json" -Body $body

# 5. Получить телеметрию
Invoke-RestMethod -Uri "http://localhost:3000/api/telemetry/latest" -Headers $headers

# 6. Получить события
Invoke-RestMethod -Uri "http://localhost:3000/api/events?limit=10" -Headers $headers
```

### JavaScript (Browser Console)

```javascript
// 1. Получить токен
fetch('http://localhost:3000/api/auth/login', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({username: 'admin', password: 'admin123'})
})
.then(r => r.json())
.then(data => {
  window.token = data.token;
  console.log('Token:', data.token);
});

// 2. Проверить возможность редактирования
fetch('http://localhost:3000/api/settings/can-edit', {
  headers: {'Authorization': 'Bearer ' + window.token}
})
.then(r => r.json())
.then(data => {
  console.log('Can edit?', data.canEdit);
  console.log('Message:', data.message);
});

// 3. Получить настройки
fetch('http://localhost:3000/api/settings', {
  headers: {'Authorization': 'Bearer ' + window.token}
})
.then(r => r.json())
.then(data => console.log('Settings:', data));

// 4. Получить телеметрию
fetch('http://localhost:3000/api/telemetry/latest', {
  headers: {'Authorization': 'Bearer ' + window.token}
})
.then(r => r.json())
.then(data => console.log('Telemetry:', data));
```

---

## 🔄 Поток данных

### Изменение настройки через Web UI

```
┌──────────┐    PUT /settings/:key    ┌──────────┐
│   Web    │ ───────────────────────► │  Server  │
│  (UI)    │                          │          │
└──────────┘                          └────┬─────┘
                                           │
                                    ┌──────┴──────┐
                                    │ Проверка:   │
                                    │ ESP32 онлайн?│
                                    └──────┬──────┘
                                           │
                    ┌──────────────────────┴──────────────────────┐
                    │                                             │
              ✅ Онлайн                                      ❌ Офлайн
                    │                                             │
                    ▼                                             ▼
          ┌──────────────────┐                        ┌──────────────────┐
          │ 1. device_cache  │                        │ HTTP 423 Locked  │
          │ 2. parameters    │                        │ "Устройство      │
          │ 3. command queue │                        │  недоступно"     │
          │ 4. WebSocket     │                        └──────────────────┘
          └────────┬─────────┘
                   │
                   ▼
          ┌──────────────────┐
          │      ESP32       │
          │ (получит команду │
          │  при sync)       │
          └──────────────────┘
```

### Sync от ESP32

```
┌──────────┐    POST /device/sync     ┌──────────┐
│  ESP32   │ ───────────────────────► │  Server  │
└──────────┘                          └────┬─────┘
                                           │
                                    ┌──────┴──────────────────┐
                                    │ 1. device_cache         │
                                    │ 2. parameters (БД!)     │
                                    │ 3. telemetry (история)  │
                                    │ 4. device status        │
                                    │ 5. events               │
                                    │ 6. commands из очереди  │
                                    │ 7. WebSocket broadcast  │
                                    └──────┬──────────────────┘
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ Разблокировка│
                                    │ UI (canEdit= │
                                    │    true)     │
                                    └──────────────┘
```

---

## 📊 Мониторинг базы данных

### Через PowerShell (psql)

```bash
# Подключиться к БД
docker-compose exec postgres psql -U postgres -d heating_system

# Посмотреть настройки
SELECT key, value FROM parameters ORDER BY key;

# Посмотреть последние события
SELECT "eventType", message, "createdAt" FROM events ORDER BY "createdAt" DESC LIMIT 10;

# Посмотреть кэш устройства
SELECT device_id, settings::jsonb, telemetry::jsonb, "lastSync" FROM device_cache;

# Выйти
\q
```

### Через Prisma Studio

```bash
cd D:\KotelAI\heating-system\backend
npx prisma studio
```

Откроется `http://localhost:5555` — визуальный интерфейс для просмотра всех таблиц.

---

## 📝 История изменений

### v1.2 (2026-06-30)
- ✅ Добавлена блокировка изменения настроек при офлайн ESP32 (HTTP 423)
- ✅ Добавлен endpoint `GET /api/settings/can-edit`
- ✅ Настройки от ESP32 теперь сохраняются в таблицу `parameters`
- ✅ Middleware `requireDeviceOnline` для `PUT /api/settings` и `PUT /api/settings/:key`

### v1.1 (2026-06-29)
- ✅ Добавлена синхронизация ESP32 через `POST /device/sync`
- ✅ Добавлена таблица `device_cache` для кэширования данных
- ✅ Добавлена поддержка фаз (L1, L2, L3)

### v1.0 (2026-06-20)
- ✅ Базовый API
- ✅ Авторизация JWT
- ✅ CRUD для пользователей и настроек
- ✅ Телеметрия и события

---

**Конец документации**
```

---

## 🚀 Как использовать

1. **Создайте файл** `API.md` в корне проекта: `D:\KotelAI\heating-system\API.md`
2. **Скопируйте содержимое** выше
3. **Сохраните** (Ctrl+S)
4. **Откройте в VS Code** — увидите красивое форматирование
5. **Для предпросмотра** нажмите `Ctrl+Shift+V`

---

## 📋 Что нового в этой версии

| Фича | Описание |
|------|----------|
| 🔒 **Блокировка при офлайн ESP32** | PUT /settings возвращает HTTP 423 |
| 🔍 **GET /settings/can-edit** | Проверка возможности редактирования |
| 💾 **Сохранение из ESP32 в БД** | Sync от ESP32 обновляет таблицу `parameters` |
| 📊 **Поток данных** | Диаграммы работы системы |
| 🗄️ **Мониторинг БД** | Команды для psql и Prisma Studio |

Готово! У вас полная актуальная документация API с учётом всех последних изменений. 🎯