### ASSISTANT
# 📄 API.md - Полная документация API системы отопления

**Создайте файл:** `D:\KotelAI\heating-system\API.md`

**Содержимое:**

```markdown
# 🔌 API Documentation - Heating System

**Base URL:** `http://localhost:3000/api`  
**Версия:** 1.1  
**Дата:** 2026-06-29

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

---

## 🔐 Авторизация

### POST /auth/login

**Описание:** Вход в систему, получение JWT токена

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

**Описание:** Выход из системы

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

**Описание:** Получить информацию о текущем пользователе

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

**Описание:** Получить список всех пользователей

**Заголовки:**
```
Authorization: Bearer <token>
```

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

**Описание:** Создать нового пользователя

**Заголовки:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

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
- `username` (string, обязательный) - логин
- `password` (string, обязательный) - пароль
- `role` (string, обязательный) - "ADMIN", "OPERATOR", "VIEWER"
- `telegramId` (string, опциональный) - Telegram ID

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

**Описание:** Обновить пользователя

**Заголовки:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

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

**Описание:** Удалить пользователя

**Ответ (200 OK):**
```json
{
  "message": "User deleted"
}
```

---

## ⚙️ Настройки

### GET /settings

**Описание:** Получить все настройки системы

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
    "description": "Целевая температура помещения",
    "updatedAt": "2026-06-29T14:35:10.801Z"
  },
  {
    "key": "room_temp_threshold_on",
    "value": "21.5",
    "description": "Порог включения отопления",
    "updatedAt": "2026-06-29T14:35:10.801Z"
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

### PUT /settings/:key

**Описание:** Изменить одну настройку

**Требуемая роль:** ADMIN, OPERATOR

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

**Пример (PowerShell):**
```powershell
$headers = @{Authorization="Bearer $token"}
$body = @{value="23.5"} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/settings/room_temp_target" `
  -Method PUT -Headers $headers -ContentType "application/json" -Body $body
```

---

### PUT /settings

**Описание:** Массовое изменение настроек

**Требуемая роль:** ADMIN, OPERATOR

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

**Описание:** Получить последние показания всех датчиков

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200 OK):**
```json
{
  "room_temp": {
    "value": 22.3,
    "timestamp": "2026-06-29T14:35:10.801Z"
  },
  "boiler_temp": {
    "value": 58.5,
    "timestamp": "2026-06-29T14:35:10.801Z"
  },
  "floor_temp": {
    "value": 24.8,
    "timestamp": "2026-06-29T14:35:10.801Z"
  },
  "accumulator_temp": {
    "value": 65.0,
    "timestamp": "2026-06-29T14:35:10.801Z"
  },
  "outdoor_temp": {
    "value": -5.2,
    "timestamp": "2026-06-29T14:35:10.801Z"
  },
  "phases": {
    "value": {
      "L1": true,
      "L2": true,
      "L3": true
    },
    "timestamp": "2026-06-29T14:35:10.801Z"
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

**Описание:** Получить историю показаний

**Query параметры:**
- `parameter` (string) - параметр (например, `room_temp`)
- `hours` (number) - период в часах (по умолчанию 24)

**Пример:**
```
GET /api/telemetry/history?parameter=room_temp&hours=48
```

---

## 📋 События

### GET /events

**Описание:** Получить журнал событий

**Query параметры:**
- `limit` (number) - количество (по умолчанию 100)

**Ответ (200 OK):**
```json
[
  {
    "id": 1,
    "eventType": "INFO",
    "message": "User admin logged in",
    "createdAt": "2026-06-29T14:35:10.801Z"
  }
]
```

**Типы событий:**
- `INFO` - информационное
- `WARNING` - предупреждение
- `ERROR` - ошибка
- `ALARM` - аварийная ситуация

---

## 🎮 Команды

### POST /commands

**Описание:** Отправить команду устройству

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

**Описание:** Получить команды в очереди (для ESP32)

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

##  Устройства

### GET /device/status

**Описание:** Получить статус устройства

**Ответ (200 OK):**
```json
{
  "name": "ESP32-001",
  "online": true,
  "lastSeen": "2026-06-29T14:35:10.801Z",
  "deviceStatus": {
    "boiler": "on",
    "elec_boiler": "off",
    "floor_pump": "on",
    "radiator_pump": "on"
  },
  "uptime": 3600,
  "firmware": "1.0.0",
  "lastSync": "2026-06-29T14:35:10.801Z"
}
```

---

### POST /device/telemetry

**Описание:** Отправить телеметрию от устройства

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

**Описание:** Подтвердить выполнение команды

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

**Описание:** Полная синхронизация данных от ESP32

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

## 🔑 Аутентификация

Все защищённые эндпоинты требуют заголовок:
```
Authorization: Bearer <token>
```

**Срок действия токена:** 24 часа

---

## 🚫 Коды ошибок

| Код | Описание |
|-----|----------|
| 400 | Bad Request |
| 401 | Unauthorized - токен отсутствует или невалиден |
| 403 | Forbidden - недостаточно прав |
| 404 | Not Found |
| 500 | Internal Server Error |

---

##  Примеры использования

### PowerShell

```powershell
# 1. Получить токен
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"username":"admin","password":"admin123"}'
$token = $response.token

# 2. Получить настройки
$headers = @{Authorization="Bearer $token"}
Invoke-RestMethod -Uri "http://localhost:3000/api/settings" -Headers $headers

# 3. Изменить настройку
$body = @{value="23.5"} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/settings/room_temp_target" `
  -Method PUT -Headers $headers -ContentType "application/json" -Body $body

# 4. Получить телеметрию
Invoke-RestMethod -Uri "http://localhost:3000/api/telemetry/latest" -Headers $headers

# 5. Получить события
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

// 2. Получить настройки
fetch('http://localhost:3000/api/settings', {
  headers: {'Authorization': 'Bearer ' + window.token}
})
.then(r => r.json())
.then(data => console.log('Settings:', data));

// 3. Получить телеметрию
fetch('http://localhost:3000/api/telemetry/latest', {
  headers: {'Authorization': 'Bearer ' + window.token}
})
.then(r => r.json())
.then(data => console.log('Telemetry:', data));
```

---

## 🎯 Быстрая шпаргалка

| Действие | Метод | URL |
|----------|-------|-----|
| Войти | POST | /auth/login |
| Получить настройки | GET | /settings |
| Изменить настройку | PUT | /settings/:key |
| Получить телеметрию | GET | /telemetry/latest |
| История телеметрии | GET | /telemetry/history?parameter=X&hours=24 |
| Получить события | GET | /events |
| Получить пользователей | GET | /users |
| Создать пользователя | POST | /users |
| Отправить команду | POST | /commands |
| Очередь команд | GET | /commands/pending |
| Статус устройства | GET | /device/status |
| Синхронизация ESP32 | POST | /device/sync |
| Подтвердить команду | POST | /device/command/:id/executed |

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

Готово! У вас полная актуальная документация API. 🎯

