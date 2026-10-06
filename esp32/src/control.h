#ifndef CONTROL_H
#define CONTROL_H

#include <Arduino.h>
#include "config.h"

#define MAX_EVENTS 20

struct ManualOverride {
    bool active = false;
    bool forcedState = false;
    bool savedAutoState = false;
    unsigned long expiresAt = 0;
};

struct DeviceStates {
    bool boiler = false;
    bool elec_boiler = false;
    bool floor_pump = false;
    bool radiator_pump = false;

    ManualOverride boiler_mo;
    ManualOverride elec_boiler_mo;
    ManualOverride floor_pump_mo;
    ManualOverride radiator_pump_mo;
};

struct DeviceEvent {
    uint32_t id;
    uint32_t timestamp;
    const char* type;
    const char* message;
};

class Control {
public:
    void begin();
    void update();

    void setManualOverride(uint8_t device, bool state);
    void clearAllManualOverrides();
    void emergencyStop();

    DeviceStates getStates();
    bool phasesOk();

    bool isManualActive(uint8_t device);
    unsigned long getManualRemaining(uint8_t device);

    // Расписание
    bool isInSchedule(uint8_t device);
    void adjustSchedule(uint8_t device, uint8_t slot, uint8_t field, int8_t dir);
    void toggleScheduleEnabled(uint8_t device);
    void toggleSlotEnabled(uint8_t device, uint8_t slot);
    void clearSlot(uint8_t device, uint8_t slot);
    void setSlotTime(uint8_t device, uint8_t slot, uint8_t startH, uint8_t startM, uint8_t endH, uint8_t endM);

    bool hasPendingEvents();
    DeviceEvent getNextEvent();
    int getEventCount();
    void addEvent(const char* type, const char* message);

    SystemSettings settings;
    DeviceStates states;
    bool phaseL1 = false, phaseL2 = false, phaseL3 = false;

private:
    void checkManualOverrides();
    void controlBoiler();
    void controlElecBoiler();
    void controlFloorPump();
    void controlRadiatorPump();
    void checkCriticalConditions();
    void checkPhases();
    void decodePhases(int adc, bool &l1, bool &l2, bool &l3);
    bool isNightMode();
    void generateStateChangeEvents();

    void setBoiler(bool state);
    void setElecBoiler(bool state);
    void setFloorPump(bool state);
    void setRadiatorPump(bool state);

    ManualOverride* getMO(uint8_t device);
    bool getDeviceState(uint8_t device);
    void setDeviceState(uint8_t device, bool state);

    void updateRelay(uint8_t pin, bool &currentState, bool newState, const char* name);
    void printRelayStatus();

    DeviceStates previousStates;

    bool pendL1 = false, pendL2 = false, pendL3 = false;
    uint8_t phaseDebounce = 0;

    DeviceEvent eventQueue[MAX_EVENTS];
    uint8_t eqHead = 0;
    uint8_t eqTail = 0;
    uint8_t eqCount = 0;
    uint32_t eventIdCounter = 1;

    unsigned long lastControlTime = 0;
    unsigned long lastStatusPrint = 0;
};

extern Control control;
#endif // CONTROL_H