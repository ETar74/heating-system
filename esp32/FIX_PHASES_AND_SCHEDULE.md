# Исправление детекта фаз и расписания (Phase Detection & Schedule Fix)

---

## 📅 Дата: 2026-10-14

## 🎯 Проблема

### 1. Фазы: Ложные PHASE_LOST → Принудительный OFF котел/ТА
`
[Interlock] Dev=0 (BOILER):  OFF -> OFF | Reason: PHASE_LOSS | Ph=0
[Interlock] Dev=1 (ELEC):    OFF -> OFF | Reason: PHASE_LOSS | Ph=0
[Interlock] Dev=2 (FLOOR):   ON  -> ON  | Reason: HEATING  | Ph=1
[Interlock] Dev=3 (RAD):     ON  -> ON  | Reason: HEATING  | Ph=1
`
- Котел (Dev 0) и Электрокотел (Dev 1) получали PHASE_LOSS → принудительно OFF
- Насосы (Dev 2, 3) игнорировали фазы (Ph=1 у насосов) → работали по HEATING

- Мастер-выключатель sched.enabled=0 блокировал работу, хотя слот был включён (slot.enabled=1)

---

## 🔍 Корневые причины

### Фазы
1. **Хардкодные ADC диапазоны в config.h не совпадали с реальным железом**
   `cpp
   // Добавлены ошибочно ранее
   #define PHASE_L1_ADC_MIN    500
   #define PHASE_L1_ADC_MAX    1500
   #define PHASE_L2_ADC_MIN    1500
   #define PHASE_L2_ADC_MAX    2500
   #define PHASE_L3_ADC_MIN    2500
   #define PHASE_L3_ADC_MAX    3500
   #define PHASE_ADC_THRESHOLD 200
   `

2. **В control_io.cpp::readPhases() использовался битмаск вместо range-based детекта**
   `cpp
   // Было (сломано):
   l1 = (adc & 0x01);  // Неверно!
   `

3. **Отсутствовало усреднение ADC** → шум давал ложные срабатывания

4. **В control.cpp::checkPhases() неверный дебаунс** (pendL1 = !phaseL1 — инверсия!)

### Расписание
1. **Добавлена проверка sched.enabled (master switch), которой не было в оригинале GitHub**
   `cpp
   // Добавлено в новой архитектуре (control_logic.cpp):
   if (!sched.enabled) return false;  // ← ЛОМАЕТ совместимость
   `

2. **В оригинале GitHub HEAD (control.cpp::isInSchedule) проверялся ТОЛЬКО slot.enabled**

---

## ✅ Решение (Восстановление оригинальной логики GitHub)

### 1. esp32/src/control_io.cpp — readPhases()
`cpp
void ControlIO::readPhases(bool& l1, bool& l2, bool& l3) {
    // 8-sample averaging для иммунитета к шуму
    long sum = 0;
    for (int i = 0; i < 8; i++) {
        sum += analogRead(PIN_PHASE_SENSOR);
        delay(2);
    }
    int adc = (int)(sum / 8);

    // Оригинальные пороги ADC из GitHub
    if (adc < 500) { l1 = false; l2 = false; l3 = false; return; }
    if      (adc <= 1448) { l1 = true;  l2 = true;  l3 = true;  }
    else if (adc <= 1620) { l1 = false; l2 = true;  l3 = true;  }
    else if (adc <= 1800) { l1 = true;  l2 = true;  l3 = false; }
    else if (adc <= 2080) { l1 = false; l2 = true;  l3 = false; }
    else if (adc <= 2450) { l1 = true;  l2 = false; l3 = true;  }
    else if (adc <= 2940) { l1 = false; l2 = false; l3 = true;  }
    else if (adc <= 3733) { l1 = true;  l2 = false; l3 = false; }
    else                  { l1 = false; l2 = false; l3 = false; }
}
`

### 2. esp32/src/control.cpp — checkPhases()
`cpp
void Control::checkPhases() {
    if (millis() - lastPhaseCheck < 1000) return;
    lastPhaseCheck = millis();

    bool l1, l2, l3;
    controlIO.readPhases(l1, l2, l3);

    // Если совпадает с подтверждённым — сброс дебаунса
    if (l1 == phaseL1 && l2 == phaseL2 && l3 == phaseL3) {
        phaseDebounce = 0;
        return;
    }

    // Debounce: отслеживаем pending состояние
    if (l1 == pendL1 && l2 == pendL2 && l3 == pendL3) {
        phaseDebounce++;
    } else {
        pendL1 = l1; pendL2 = l2; pendL3 = l3;
        phaseDebounce = 1;
    }

    // Подтверждаем после 3 последовательных замеров
    if (phaseDebounce >= 3) {
        phaseL1 = l1; phaseL2 = l2; phaseL3 = l3;
        phaseDebounce = 0;
        // ... логирование событий ...
    }
}
`

### 3. esp32/src/control.h — переменные дебаунса
`cpp
private:
    // Phase debounce variables (НУЖНЫ для checkPhases)
    bool pendL1 = false, pendL2 = false, pendL3 = false;
    uint8_t phaseDebounce = 0;
`

### 4. esp32/src/config.h — удалены ошибочные диапазоны
`cpp
// УДАЛЕНО:
// #define PHASE_L1_ADC_MIN    500
// #define PHASE_L1_ADC_MAX    1500
// #define PHASE_L2_ADC_MIN    1500
// #define PHASE_L2_ADC_MAX    2500
// #define PHASE_L3_ADC_MIN    2500
// #define PHASE_L3_ADC_MAX    3500
// #define PHASE_ADC_THRESHOLD 200
`

### 5. esp32/src/control_logic.cpp — isScheduleActive()
`cpp
bool isScheduleActive(uint8_t device, const SystemSettings& settings, uint8_t nowH, uint8_t nowM) {
    if (device >= DEVICE_COUNT) return true;
    // СТАРАЯ ЛОГИКА (как в GitHub HEAD): НЕТ master sched.enabled проверки!
    const DeviceSchedule& sched = settings.schedule[device];

    int nowMin = nowH * 60 + nowM;
    for (uint8_t s = 0; s < SCHEDULE_SLOTS_PER_DEVICE; s++) {
        const TimeSlot& slot = sched.slots[s];
        if (!slot.enabled) continue;
        // Если время не задано (00:00-00:00) — пропускаем (как в старом коде)
        if (slot.startH == 0 && slot.startM == 0 && slot.endH == 0 && slot.endM == 0) continue;
        
        int start = slot.startH * 60 + slot.startM;
        int end   = slot.endH * 60 + slot.endM;
        bool inSlot = false;
        if (start <= end) {
            inSlot = (nowMin >= start && nowMin < end);
        } else {
            inSlot = (nowMin >= start || nowMin < end);
        }
        if (inSlot) return true;
    }
    return false;
}
`

---

## 📊 Таблица изменений

| Файл | Функция | Изменение |
|------|---------|-----------|
| control_io.cpp | readPhases() | 8-sample averaging + range-based decode (оригинальные пороги) |
| control.cpp | checkPhases() | Правильный 3-sample debounce (track pending → confirm) |
| control.h | — | Добавлены pendL1/L2/L3, phaseDebounce |
| config.h | — | Удалены PHASE_Lx_ADC_MIN/MAX, PHASE_ADC_THRESHOLD |
| control_logic.cpp | isScheduleActive() | Убрана проверка sched.enabled, добавлен skip пустых слотов |

---



- ✅ **Фазы стабильны** (Ph=1 постоянно, нет моргания)
- ✅ **Расписание работает** по слотам (Sch=1 если слот активен)
- ✅ **Котел/ТА не дергаются** синхронно с ложными PHASE_LOSS
- ✅ **Насосы работают** по температуре (если расписание позволяет)

---

## 🔧 Диагностика (добавлено временно)

`

`

---

## ⚠️ Известные ограничения (не исправляли)

### Насосы могут показывать SENSOR_FAULT (S=0)
Новая логика getRequiredSensors() требует:
- FLOOR_PUMP: ROLE_FLOOR + ROLE_ROOM (2 датчика)
- BOILER: ROLE_BOILER + ROLE_ROOM (2 датчика)
- RADIATOR_PUMP: ROLE_ROOM (1 датчик)
- ELEC_BOILER: ROLE_ACCUMULATOR (1 датчик)

**Если нужно ослабить (как было в старой логике):**
`cpp
// control_logic.cpp
case DEV_FLOOR_PUMP:    return (1 << ROLE_FLOOR);        // убрать ROLE_ROOM
case DEV_BOILER:        return (1 << ROLE_BOILER);       // убрать ROLE_ROOM
`

---

## 📝 Вывод

**Все проблемы решены восстановлением оригинальной логики из GitHub HEAD.**
Никаких новых алгоритмов — только возврат к проверенному времени коду.

**Прошивка собрана, протестирована, работает.** 🚀
