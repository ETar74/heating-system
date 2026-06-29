## 📄 Файл: `API.md`

**Где создать:** `D:\KotelAI\heating-system\API.md`

**Содержимое:**

```markdown
# 🔌 API Documentation - Heating System

**Base URL:** `http://localhost:3000/api`  
**Версия:** 1.0  
**Дата:** 2026-06-26

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
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"admin","password":"admin123"}'
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
  },
  {
    "id": 2,
    "username": "operator",
    "role": "OPERATOR",
    "telegramId": null,
    "createdAt": "2026-06-21T14:30:00.000Z"
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
- `username` (string, обязательный) - логин пользователя
- `password` (string, обязательный) - пароль
- `role` (string, обязательный) - роль: "ADMIN", "OPERATOR", "VIEWER"
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

**Описание:** Обновить данные пользователя

**Заголовки:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Параметры URL:**
- `id` (number) - ID пользователя

**Тело запроса:**
```json
{
  "username": "newname",
  "password": "newpassword",
  "role": "OPERATOR",
  "telegramId": "123456789"
}
```

**Примечание:** Все поля опциональны. Если пароль не указан, он не меняется.

**Ответ (200 OK):**
```json
{
  "id": 3,
  "username": "newname",
  "role": "OPERATOR"
}
```

---

### DELETE /users/:id

**Описание:** Удалить пользователя

**Заголовки:**
```
Authorization: Bearer <token>
```

**Параметры URL:**
- `id` (number) - ID пользователя

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
    "updatedAt": "2026-06-26T09:54:10.801Z"
  },
  {
    "key": "boiler_temp_target",
    "value": "60.0",
    "description": "Целевая температура котла",
    "updatedAt": "2026-06-26T09:54:10.801Z"
  },
  {
    "key": "floor_pump_on_temp",
    "value": "25",
    "description": "Температура включения насоса теплого пола",
    "updatedAt": "2026-06-26T09:54:10.801Z"
  }
]
```

**Доступные ключи настроек:**
- `room_temp_target` - целевая температура помещения
- `room_temp_threshold_on` - порог включения отопления
- `room_temp_threshold_off` - порог выключения отопления
- `room_temp_hysteresis` - гистерезис температуры помещения
- `boiler_temp_target` - целевая температура котла
- `boiler_temp_threshold_on` - порог включения котла
- `boiler_temp_threshold_off` - порог выключения котла
- `boiler_temp_hysteresis` - гистерезис температуры котла
- `floor_temp_target` - целевая температура теплого пола
- `floor_pump_on_temp` - температура включения насоса ТП
- `floor_pump_off_temp` - температура выключения насоса ТП
- `boiler_max_temp` - максимальная температура котла
- `night_start` - начало ночного режима (HH:MM)
- `night_end` - конец ночного режима (HH:MM)

---

### PUT /settings/:key

**Описание:** Изменить одну настройку

**Требуемая роль:** ADMIN, OPERATOR

**Заголовки:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Параметры URL:**
- `key` (string) - ключ настройки (например, `room_temp_target`)

**Тело запроса:**
```json
{
  "value": "23.5"
}
```

**Ответ (200 OK):**
```json
{
  "key": "room_temp_target",
  "value": "23.5",
  "updatedAt": "2026-06-26T10:15:30.000Z"
}
```

**Пример (PowerShell):**
```powershell
$headers = @{Authorization="Bearer $token"}
$body = @{value="23.5"} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/settings/room_temp_target" -Method PUT -Headers $headers -ContentType "application/json" -Body $body
```

---

### PUT /settings

**Описание:** Массовое изменение настроек

**Требуемая роль:** ADMIN, OPERATOR

**Заголовки:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "parameters": [
    {
      "key": "room_temp_target",
      "value": "22.0"
    },
    {
      "key": "boiler_temp_target",
      "value": "60.0"
    },
    {
      "key": "night_start",
      "value": "22:00"
    }
  ]
}
```

**Ответ (200 OK):**
```json
{
  "message": "Settings updated"
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
    "value": "22.3",
    "timestamp": "2026-06-26T09:54:10.801Z"
  },
  "boiler_temp": {
    "value": "58.5",
    "timestamp": "2026-06-26T09:54:10.801Z"
  },
  "floor_temp": {
    "value": "24.8",
    "timestamp": "2026-06-26T09:54:10.801Z"
  },
  "outdoor_temp": {
    "value": "-5.2",
    "timestamp": "2026-06-26T09:54:10.801Z"
  },
  "accumulator_temp": {
    "value": "65.0",
    "timestamp": "2026-06-26T09:54:10.801Z"
  }
}
```

---

### GET /telemetry/history

**Описание:** Получить историю показаний датчика

**Заголовки:**
```
Authorization: Bearer <token>
```

**Query параметры:**
- `parameter` (string) - название параметра (например, `room_temp`)
- `hours` (number, опциональный) - период в часах (по умолчанию 24)

**Пример запроса:**
```
GET /api/telemetry/history?parameter=room_temp&hours=48
```

**Ответ (200 OK):**
```json
[
  {
    "id": 1,
    "parameter": "room_temp",
    "value": "22.3",
    "timestamp": "2026-06-26T09:54:10.801Z"
  },
  {
    "id": 2,
    "parameter": "room_temp",
    "value": "22.1",
    "timestamp": "2026-06-26T09:49:10.801Z"
  }
]
```

---

## 📋 События

### GET /events

**Описание:** Получить журнал событий

**Заголовки:**
```
Authorization: Bearer <token>
```

**Query параметры:**
- `limit` (number, опциональный) - количество событий (по умолчанию 100)

**Пример запроса:**
```
GET /api/events?limit=50
```

**Ответ (200 OK):**
```json
[
  {
    "id": 1,
    "eventType": "INFO",
    "message": "User admin logged in",
    "createdAt": "2026-06-26T09:54:10.801Z"
  },
  {
    "id": 2,
    "eventType": "WARNING",
    "message": "High temperature detected",
    "createdAt": "2026-06-26T09:50:00.000Z"
  },
  {
    "id": 3,
    "eventType": "ERROR",
    "message": "Sensor connection lost",
    "createdAt": "2026-06-26T09:45:00.000Z"
  }
]
```

**Типы событий:**
- `INFO` - информационное сообщение
- `WARNING` - предупреждение
- `ERROR` - ошибка
- `ALARM` - аварийная ситуация

---

## 🎮 Команды

### POST /commands

**Описание:** Отправить команду устройству

**Требуемая роль:** ADMIN, OPERATOR

**Заголовки:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "command": "boiler_on",
  "payload": {}
}
```

**Доступные команды:**
- `boiler_on` - включить котёл
- `boiler_off` - выключить котёл
- `floor_pump_on` - включить насос тёплого пола
- `floor_pump_off` - выключить насос тёплого пола
- `radiator_pump_on` - включить насос радиаторов
- `radiator_pump_off` - выключить насос радиаторов

**Ответ (200 OK):**
```json
{
  "id": 1,
  "command": "boiler_on",
  "payload": {},
  "status": "pending",
  "createdAt": "2026-06-26T10:15:30.000Z"
}
```

---

### GET /commands/pending

**Описание:** Получить список команд в очереди (для ESP32)

**Заголовки:** Не требуются (публичный эндпоинт)

**Ответ (200 OK):**
```json
[
  {
    "id": 1,
    "command": "SET_SETTING",
    "payload": {
      "key": "room_temp_target",
      "value": 23
    },
    "status": "pending",
    "createdAt": "2026-06-26T10:15:30.000Z"
  }
]
```

---

## 📡 Устройства

### GET /device/status

**Описание:** Получить статус устройства

**Заголовки:**
```
Authorization: Bearer <token>
```

**Ответ (200 OK):**
```json
{
  "name": "ESP32-001",
  "online": true,
  "lastSeen": "2026-06-26T09:54:10.801Z",
  "deviceStatus": {
    "boiler": "on",
    "floor_pump": "off",
    "radiator_pump": "on",
    "elec_boiler": "off"
  },
  "uptime": 3600,
  "firmware": "1.0.0",
  "lastSync": "2026-06-26T09:54:10.801Z"
}
```

---

### POST /device/telemetry

**Описание:** Отправить телеметрию от устройства (для ESP32)

**Заголовки:** Не требуются (публичный эндпоинт)

**Тело запроса:**
```json
{
  "serialNumber": "ESP32-001",
  "data": {
    "room_temp": 22.3,
    "boiler_temp": 58.5,
    "floor_temp": 24.8,
    "outdoor_temp": -5.2,
    "accumulator_temp": 65.0
  }
}
```

**Ответ (200 OK):**
```json
{
  "success": true
}
```

---

### POST /device/command/:id/executed

**Описание:** Подтвердить выполнение команды (для ESP32)

**Заголовки:** Не требуются (публичный эндпоинт)

**Параметры URL:**
- `id` (number) - ID команды

**Тело запроса:**
```json
{
  "success": true,
  "message": "Command executed successfully"
}
```

**Ответ (200 OK):**
```json
{
  "success": true
}
```

---

## 🔄 ESP32 Sync

### POST /device/sync

**Описание:** Полная синхронизация данных от ESP32

**Заголовки:** Не требуются (публичный эндпоинт)

**Тело запроса:**
```json
{
  "deviceId": "ESP32-001",
  "timestamp": 1735000000,
  "uptime": 3600,
  "firmware": "1.0.0",
  "settings": {
    "room_temp_target": 22.0,
    "boiler_temp_target": 60,
    "floor_pump_on_temp": 25,
    "night_start": "22:00",
    "night_end": "06:00"
  },
  "telemetry": {
    "room_temp": 22.3,
    "boiler_temp": 58.5,
    "floor_temp": 24.8,
    "outdoor_temp": -5.2,
    "accumulator_temp": 65.0
  },
  "device_status": {
    "boiler": "on",
    "floor_pump": "off",
    "radiator_pump": "on",
    "elec_boiler": "off"
  },
  "events": [
    {
      "id": 1,
      "timestamp": 1735000000,
      "type": "INFO",
      "message": "Boiler turned ON"
    },
    {
      "id": 2,
      "timestamp": 1734999500,
      "type": "WARNING",
      "message": "Outdoor temperature below -5°C"
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

Все защищённые эндпоинты требуют заголовок `Authorization`:

```
Authorization: Bearer <token>
```

**Как получить токен:**
1. Отправьте POST запрос на `/api/auth/login`
2. Получите токен из ответа
3. Используйте его в заголовке для всех последующих запросов

**Срок действия токена:** 24 часа

---

## 🚫 Коды ошибок

| Код | Описание |
|-----|----------|
| 400 | Bad Request - неверный формат запроса |
| 401 | Unauthorized - токен отсутствует или невалиден |
| 403 | Forbidden - недостаточно прав |
| 404 | Not Found - ресурс не найден |
| 500 | Internal Server Error - ошибка сервера |

**Пример ошибки:**
```json
{
  "error": "Access token required"
}
```

---

## 📝 Примеры использования

### PowerShell

```powershell
# 1. Получить токен
$loginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"admin","password":"admin123"}'
$token = $loginResponse.token

# 2. Получить настройки
$headers = @{Authorization="Bearer $token"}
$settings = Invoke-RestMethod -Uri "http://localhost:3000/api/settings" -Headers $headers
$settings | ConvertTo-Json

# 3. Изменить настройку
$body = @{value="23.5"} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/settings/room_temp_target" -Method PUT -Headers $headers -ContentType "application/json" -Body $body

# 4. Получить телеметрию
$telemetry = Invoke-RestMethod -Uri "http://localhost:3000/api/telemetry/latest" -Headers $headers
$telemetry | ConvertTo-Json

# 5. Получить события
$events = Invoke-RestMethod -Uri "http://localhost:3000/api/events?limit=10" -Headers $headers
$events | ConvertTo-Json
```

### cURL (Linux/Mac)

```bash
# 1. Получить токен
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

# 2. Получить настройки
curl -X GET http://localhost:3000/api/settings \
  -H "Authorization: Bearer $TOKEN"

# 3. Изменить настройку
curl -X PUT http://localhost:3000/api/settings/room_temp_target \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"value":"23.5"}'

# 4. Получить телеметрию
curl -X GET http://localhost:3000/api/telemetry/latest \
  -H "Authorization: Bearer $TOKEN"
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

// 3. Изменить настройку
fetch('http://localhost:3000/api/settings/room_temp_target', {
  method: 'PUT',
  headers: {
    'Authorization': 'Bearer ' + window.token,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({value: '23.5'})
})
.then(r => r.json())
.then(data => console.log('Updated:', data));
```

---

## 🎯 Быстрая шпаргалка

| Действие | Метод | URL | Тело |
|----------|-------|-----|------|
| Войти | POST | /auth/login | `{"username":"admin","password":"admin123"}` |
| Получить настройки | GET | /settings | - |
| Изменить настройку | PUT | /settings/:key | `{"value":"23.5"}` |
| Получить телеметрию | GET | /telemetry/latest | - |
| Получить события | GET | /events | - |
| Получить пользователей | GET | /users | - |
| Создать пользователя | POST | /users | `{"username":"...","password":"...","role":"..."}` |
| Отправить команду | POST | /commands | `{"command":"boiler_on","payload":{}}` |
| Статус устройства | GET | /device/status | - |
| Синхронизация ESP32 | POST | /device/sync | (полный JSON) |

---

## 📞 Поддержка

**Документация:** Этот файл  
**GitHub:** https://github.com/ETar74/heating-system  
**Автор:** ETar74

---

**Конец документации**
```

---

## 🚀 Как использовать

1. **Создайте файл** `API.md` в корне проекта
2. **Скопируйте содержимое** выше
3. **Сохраните файл** (Ctrl+S)
4. **Откройте в VS Code** — увидите красивое форматирование
5. **Для предпросмотра** нажмите `Ctrl+Shift+V` в VS Code

---

## ✅ Что вы получили

Полный справочник по всем API вашей системы с:
- 📋 Списком всех эндпоинтов
- 📝 Примерами запросов и ответов
- 🔑 Описанием аутентификации
- 🚫 Коды ошибок
- 💻 Примеры кода для PowerShell, cURL, JavaScript
- 🎯 Быстрая шпаргалка
