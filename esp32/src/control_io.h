#ifndef CONTROL_IO_H
#define CONTROL_IO_H

#include "config.h"
#include "control.h"

// ===== Аппаратный слой (HAL) — только GPIO и NVS =====
// Не знает про гистерезис, расписание, датчики

class ControlIO {
public:
    void begin();
    
    // Применение решения интерлока к железу
    void applyRelayDecision(DeviceId device, const RelayDecision& decision);
    
    // Прямое управление (для emergencyStop, manual override API)
    void setBoiler(bool state);
    void setElecBoiler(bool state);
    void setFloorPump(bool state);
    void setRadiatorPump(bool state);
    
    // Сохранение состояний в NVS
    void saveDeviceStates(const DeviceStates& states);
    
    // Чтение фаз (ADC)
    void readPhases(bool& l1, bool& l2, bool& l3);
    
    // Статус для логов
    void printRelayStatus();

private:
    // Низкоуровневое обновление реле с проверкой изменений
    void updateRelay(uint8_t pin, bool& currentState, bool newState, const char* name);
    
    uint8_t relayPins[DEVICE_COUNT] = {
        PIN_RELAY_BOILER,
        PIN_RELAY_ELEC,
        PIN_RELAY_FLOOR,
        PIN_RELAY_RADIATOR
    };
    
    const char* relayNames[DEVICE_COUNT] = {
        "BOILER", "ELEC_BOILER", "FLOOR_PUMP", "RADIATOR_PUMP"
    };
};

extern ControlIO controlIO;

#endif // CONTROL_IO_H