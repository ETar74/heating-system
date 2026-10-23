## 2. Уровень ESP32 (Firmware)

### 2.1 Чтение фаз (Phase Reading)

```text
analogRead(PIN_PHASE_SENSOR)
│
├─ 8-sample averaging (delay 2ms × 8)
│   sum / 8 = adc
│
│   Range decode:
│   adc ≤ 1448  → L1=1 L2=1 L3=1  (все фазы есть)
│   1448 < adc ≤ 1620 → L1=0 L2=1 L3=1  (нет L1)
│   1620 < adc ≤ 1800 → L1=1 L2=1 L3=0  (нет L3)
│   1800 < adc ≤ 2080 → L1=0 L2=1 L3=0  (нет L1+L3? или L2?)
│   2080 < adc ≤ 2450 → L1=1 L2=0 L3=1  (нет L2)
│   2450 < adc ≤ 2940 → L1=0 L2=0 L3=1  (нет L1+L2)
│   2940 < adc ≤ 3733 → L1=1 L2=0 L3=0  (нет L2+L3)
│   adc > 3733   → L1=0 L2=0 L3=0  (фазы потеряны)
```
# DATA FLOW — Heating System ESP32 + Frontend + Backend

## 1. Обзор потока данных

Система управления отоплением состоит из трех основных частей:
- **ESP32 Firmware** — чтение датчиков, управление реле, фазы напряжения
- **Backend API** (Node.js + Express + Prisma) — хранение настроек, API endpoints
- **Frontend** (React + Next.js) — интерфейс пользователя, настройки, мониторинг

## 2. Уровень ESP32 (Firmware)

### 2.1 Чтение фаз (Phase Reading)

```text
analogRead(PIN_PHASE_SENSOR)
│
├─ 8-sample averaging (delay 2ms × 8)
│   sum / 8 = adc
│
│   Range decode:
│   adc ≤ 1448  → L1=1 L2=1 L3=1  (все фазы есть)
│   1448 < adc ≤ 1620 → L1=0 L2=1 L3=1  (нет L1)
│   1620 < adc ≤ 1800 → L1=1 L2=1 L3=0  (нет L3)
│   1800 < adc ≤ 2080 → L1=0 L2=1 L3=0  (нет L1+L3? или L2?)
│   2080 < adc ≤ 2450 → L1=1 L2=0 L3=1  (нет L2)
│   2450 < adc ≤ 2940 → L1=0 L2=0 L3=1  (нет L1+L2)
│   2940 < adc ≤ 3733 → L1=1 L2=0 L3=0  (нет L2+L3)
│   adc > 3733   → L1=0 L2=0 L3=0  (фазы потеряны)
```

### 2.2 Дебаунс фаз (Phase Debounce)

```text
checkPhases() вызывается каждые 1000ms
│
├─ l1==phaseL1 && l2==phaseL2 && l3==phaseL3 → phaseDebounce=0 (сброс)
│
├─ l1==pendL1 && l2==pendL2 && l3==pendL3 → phaseDebounce++
│
├─ иначе → pendL1/2/3 = l1/l2/l3, phaseDebounce=1
│
└─ phaseDebounce ≥ 3 → phaseL1/2/3 = l1/l2/l3, phaseDebounce=0, событие logged
```
### 2.3 Логика реле (Relay Decision)

```text
evaluateAllRelays() вызывает computeRelayDecision() для каждого устройства

│
├─ 1. SENSOR FAULT: checkSensorsValid(getRequiredSensors(device))
│   └─ при invalid → sensorOk=false, reason=SENSOR_FAULT, РАННИЙ ВОЗВРАТ
│
├─ 2. CRITICAL LIMIT: boiler > CRITICAL_BOILER_TEMP_MAX / acc > CRITICAL_ACC_MAX
│   └─ при превышении → criticalOk=false
│
├─ 3. PHASE LOSS: !phaseL1 && !phaseL2 && !phaseL3 → phasesOk=false
│   └─ при потере фаз → early return, relays OFF
│
├─ 4. MANUAL OVERRIDE: mo.active → desiredState = mo.forcedState
│
├─ 5. SCHEDULE: isScheduleActive() → scheduleOk
│
└─ 6. TEMPERATURE LOGIC: hysteresis (on/off thresholds)
  └─ desiredState = ON if temp < on_threshold
              = OFF if temp > off_threshold
```
## 3. Backend API (Node.js + Prisma)

### 3.1 API эндпоинты

```http
GET    /api/device/settings        — получить настройки устройства
PUT    /api/device/settings        — обновить настройки
GET    /api/device/states          — получить текущее состояние реле
POST   /api/commands/manual        — ручное управление
POST   /api/commands/emergency   — аварийная остановка
```
## 4. Frontend (React + Next.js)

### 4.1 Вкладка Настройки (Settings Tab)

```jsx
// Пример компонента расписания
<Tab label="Schedule">
  <Card className="device-schedule">
    <Label className="switch">
      <input
        type="checkbox"
        checked={schedule.enabled}
        onChange={toggleMasterSchedule}
      />
      {schedule.enabled ? "Вкл" : "Выкл"}
    </Label>
    {schedule.slots.map((slot, i) => (
      <SlotRow key={i} index={i} slot={slot} />
    ))}
    <Button onClick={addNewSlot}>Добавить слот</Button>
  </Card>
</Tab>
## 5. Битовые маски датчиков (Sensor Masks)

```cpp
// getRequiredSensors(device) — возвращает маска требуемых датчиков
switch (device) {
    case DEV_BOILER:        return (1 << ROLE_BOILER)      | (1 << ROLE_ROOM);
    case DEV_ELEC_BOILER:   return (1 << ROLE_ACCUMULATOR);
    case DEV_FLOOR_PUMP:    return (1 << ROLE_FLOOR)       | (1 << ROLE_ROOM);
    case DEV_RADIATOR_PUMP: return (1 << ROLE_ROOM);
    default:                return 0;
}
```
```
## 6. Резюме потока данных

1. **ADC фаз** → 8-sample avg → range decode → phaseL1/2/3 (confirmed via 3-sample debounce)
2. **Температуры** `sensors.getData()` → `checkSensorsValid(mask)` → `sensorOk`
3. **phasesOk** = phaseL1 && phaseL2 && phaseL3
4. **scheduleOk** = `isScheduleActive(device, settings, nowH, nowM)`
5. **RelayDecision** формируется последовательно: `sensorOK → criticalOK → phasesOK → scheduleOK → manualOverride → temperatureLogic`
6. **desiredState** передается → `applyRelayDecision()` → `GPIO write` → relays ON/OFF
7. **Serial.log**: `[Interlock] Dev=N: ON/OFF | Reason: ... | S=...Ph=N`

📊 ДВЕ СХЕМЫ СОХРАНЕНИЯ РАСПИСАНИЯ
СХЕМА 1: СОХРАНЕНИЕ ЧЕРЕЗ ВЕБ-ПРИЛОЖЕНИЕ
┌─────────────────────────────────────────────────────────────────────────┐
│  ПОЛЬЗОВАТЕЛЬ → БРАУЗЕР → BACKEND → ESP32 → NVS                         │
└─────────────────────────────────────────────────────────────────────────┘

ШАГ 1: ПОЛЬЗОВАТЕЛЬ В БРАУЗЕРЕ
   ─> Открывает Settings → ScheduleSection
   └─> Выбирает устройство (0-3)
   └─> Редактирует слоты (startH, startM, endH, endM, enabled)
   └─> Нажимает "Сохранить все"

ШАГ 2: FRONTEND (React)
   └─> ScheduleSection.jsx: saveSchedule()
   └─> POST /api/device/schedule/save
   └─> Payload: { deviceId: 2, slots: [{enabled:true, startH:8, ...}, ...] }

ШАГ 3: BACKEND (Node.js/Express)
   └─> src/routes/device.js: router.post('/schedule/save')
   ─> Валидация: deviceId 0-3, slots.length === 4
   ─> Проверка isDeviceOnline()
   ─> Удаление старых pending SET_SCHEDULE команд (deleteMany)
   └─> Создание НОВОЙ команды:
       prisma.command.create({
         deviceId: device.id,
         command: 'SET_SCHEDULE',
         payload: { deviceId, slots },
         status: 'pending'
       })
   └─> Возврат: { success: true, commandId: 123 }

ШАГ 4: ESP32 ОПРОС (каждые 5-10 сек)
   └─> network.cpp: fetchCommands()
   └─> GET /api/commands/pending
   ─> Получает JSON: [{id:123, command:"SET_SCHEDULE", payload:{...}}]
   └─> Кладёт в очередь commandQueue[10]

ШАГ 5: ESP32 ОБРАБОТКА
   └─> network.cpp: processPendingCommands()
   └─> Извлекает команду из очереди
   └─> Парсит JSON payload
   └─> Применяет к control.settings.schedule[deviceId].slots[i]
   └─> storage.saveSettings(control.settings) → ЗАПИСЬ В NVS ✅
   └─> acknowledgeCommand(123, true) → POST /api/commands/123/executed

ШАГ 6: BACKEND ПОДТВЕРЖДЕНИЕ
   └─> router.post('/commands/:id/executed')
   ─> prisma.command.update({ status: 'executed' })
   └─> Команда удалена из pending ✅

РЕЗУЛЬТАТ: Расписание сохранено в NVS и на сервере.

СХЕМА 2: СОХРАНЕНИЕ ЧЕРЕЗ NEXTION (ЛОКАЛЬНО)
┌─────────────────────────────────────────────────────────────────────────┐
│  ПОЛЬЗОВАТЕЛЬ → NEXTION → UART → ESP32 → NVS → (синхронизация с сервером)│
└─────────────────────────────────────────────────────────────────────────┘

ШАГ 1: ПОЛЬЗОВАТЕЛЬ НА ДИСПЛЕЕ
   └─> Открывает страницу 7 (Расписание)
   └─> Нажимает кнопку устройства (sch_dev_0..3)
   └─> Нажимает "Редактировать слот" (sch_edit_0..3)
   └─> Переход на страницу 8 (Клавиатура)

ШАГ 2: NEXTION → UART
   └─> Кнопка "ОК" на странице 8
   └─> Nextion отправляет: prints "key_ok",0
   └─> ESP32 читает через Serial2

ШАГ 3: ESP32 ОБРАБОТКА КНОПКИ
   └─> taskNextion в main.cpp:
       cmd == "key_ok"
   └─> nextion.handleKeypadInput("key_ok")
   └─> Парсинг строки "08:00-08:10" через sscanf
   └─> control.setSlotTime(deviceId, slot, sH, sM, eH, eM)
   └─> Изменяет control.settings.schedule[deviceId].slots[slot]
   └─> Возврат на страницу 7

ШАГ 4: ESP32 СОХРАНЕНИЕ В NVS ⚠️
   └─> taskNextion в main.cpp:
       if (cmd == "key_ok") {
           storage.saveSettings(control.settings);  ← ЭТО НУЖНО ВЕРНУТЬ!
       }
   └─> storage.cpp: saveSettings()
   └─> prefs.putFloat/putUShort/putBytes → запись в NVS
   └─> Расписание сохранено в NVS ✅

ШАГ 5: СИНХРОНИЗАЦИЯ С СЕРВЕРОМ (при следующем heartbeat)
   └─> network.cpp: buildSyncPayload()
   └─> Включает schedule в тело POST /api/device/sync
   └─> Сервер получает актуальное расписание
   └─> Сервер обновляет свою БД (опционально)

РЕЗУЛЬТАТ: Расписание сохранено в NVS. Сервер узнает при следующей синхронизации.
📋 ПОЛНАЯ КАРТИНА: ГДЕ ХРАНЯТСЯ ДАННЫЕ:
┌──────────────────────────────────────────────────────────────────────┐
│                          ХРАНИЛИЩА ДАННЫХ                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  NVS (ESP32)          ← Локальное хранение, переживает перезагрузку  │
│  ├─ settings           (пороги, таймаут, расписание)                  │
│  ├─ deviceStates       (состояния реле)                               │
│  └─ sensorAddresses    (адреса датчиков)                              │
│                                                                       │
│  PostgreSQL (Сервер)  ← Центральное хранение, доступно через веб     │
│  ├─ Parameter          (настройки)                                    │
│  ├─ Command            (очередь команд для ESP32)                     │
│  ├─ Telemetry          (история температур)                           │
│  └─ Event              (журнал событий)                               │
│                                                                       │
│  Синхронизация:                                                        │
│  ESP32 → Сервер: POST /api/device/sync (включает schedule)           │
│  Сервер → ESP32: GET /api/commands/pending (SET_SCHEDULE)            │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘