#ifndef CONTROL_LOGIC_H
#define CONTROL_LOGIC_H

#include "config.h"
#include "sensors.h"  // Для SensorData

// Предварительное объявление структур из control.h (избегаем циклического включения)
struct ManualOverride;
struct DeviceStates;

// ===== Структура решения интерлока (аудит) =====
struct RelayDecision {
    bool desiredState = false;      // Итог: ВКЛ/ВЫКЛ
    const char* reason = "OK";      // Причина для лога

    // Флаги-интерлоки (все должны быть true для ON, кроме manual)
    bool sensorOk = true;           // Датчики валидны
    bool scheduleOk = true;         // Расписание разрешает
    bool logicOk = true;            // Температура требует (гистерезис)
    bool manualActive = false;      // Ручной режим активен
    bool manualState = false;       // Состояние в ручном режиме
    bool criticalOk = true;         // Нет критических аварий
    bool phasesOk = true;           // Фазы в норме
};

// ===== Входные данные для принятия решения =====
struct PhaseStatus {
    bool l1 = false, l2 = false, l3 = false;
    bool ok() const { return l1 && l2 && l3; }
};

// ===== Основные функции логики =====

// Атомарное вычисление решения для ОДНОГО реле
RelayDecision computeRelayDecision(
    DeviceId device,
    const SensorData& sensors,
    const SystemSettings& settings,
    const DeviceStates& states,
    const PhaseStatus& phases,
    bool scheduleOk
);

// Оценка всех реле за один цикл (snapshot)
void evaluateAllRelays(
    const SensorData& sensors,
    const PhaseStatus& phases,
    const SystemSettings& settings,
    const DeviceStates& states,
    RelayDecision decisions[DEVICE_COUNT],
    uint8_t nowH = 12, uint8_t nowM = 0
);

// Вспомогательные
bool isScheduleActive(uint8_t device, const SystemSettings& settings, uint8_t nowH, uint8_t nowM);
uint8_t getRequiredSensors(DeviceId device);  // Битовая маска ролей

#endif // CONTROL_LOGIC_H