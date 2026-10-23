// control_logic.cpp — Единая логика решений (Fail-Safe First)
#include "control_logic.h"
#include "control.h"
#include <string.h>

uint8_t getRequiredSensors(DeviceId device) {
    switch (device) {
        case DEV_BOILER:        return (1 << ROLE_BOILER) | (1 << ROLE_ROOM);
        case DEV_ELEC_BOILER:   return (1 << ROLE_ACCUMULATOR);
        case DEV_FLOOR_PUMP:    return (1 << ROLE_FLOOR) | (1 << ROLE_ROOM);
        case DEV_RADIATOR_PUMP: return (1 << ROLE_ROOM);
        default:                return 0;
    }
}

bool checkSensorsValid(const SensorData& sensors, uint8_t requiredMask) {
    if (requiredMask & (1 << ROLE_ROOM))        if (!sensors.room_valid)        return false;
    if (requiredMask & (1 << ROLE_BOILER))      if (!sensors.boiler_valid)      return false;
    if (requiredMask & (1 << ROLE_FLOOR))       if (!sensors.floor_valid)       return false;
    if (requiredMask & (1 << ROLE_ACCUMULATOR)) if (!sensors.accumulator_valid) return false;
    if (requiredMask & (1 << ROLE_OUTDOOR))     if (!sensors.outdoor_valid)     return false;
    return true;
}

bool isScheduleActive(uint8_t device, const SystemSettings& settings, uint8_t nowH, uint8_t nowM) {
    if (device >= DEVICE_COUNT) return true; // Или false, в зависимости от твоей логики по умолчанию
    
    const DeviceSchedule& sched = settings.schedule[device];
    int nowMin = nowH * 60 + nowM;
    
    for (uint8_t s = 0; s < SCHEDULE_SLOTS_PER_DEVICE; s++) {
        const TimeSlot& slot = sched.slots[s];
        if (!slot.enabled) continue;
        
        // Если время не задано (00:00-00:00) — пропускаем
        if (slot.startH == 0 && slot.startM == 0 && slot.endH == 0 && slot.endM == 0) continue;
        
        int start = slot.startH * 60 + slot.startM;
        int end   = slot.endH * 60 + slot.endM;
        
        bool inSlot = false;
        if (start <= end) {
            inSlot = (nowMin >= start && nowMin < end);
        } else {
            inSlot = (nowMin >= start || nowMin < end); // Переход через полночь
        }
        
        // 🛑 ИСПРАВЛЕНИЕ: Если попали в интервал, СРАЗУ возвращаем true
        if (inSlot) {
            return true;
        }
    }
    
    // Если прошли по всем слотам и ни один не подошел
    return false;
}
RelayDecision computeRelayDecision(
    DeviceId device,
    const SensorData& sensors,
    const SystemSettings& settings,
    const DeviceStates& states,
    const PhaseStatus& phases,
    bool scheduleOk
) {
    RelayDecision d;

    // 1. SENSOR FAULT
    uint8_t requiredMask = getRequiredSensors(device);
    if (!checkSensorsValid(sensors, requiredMask)) {
        d.sensorOk = false;
        d.reason = "SENSOR_FAULT";
        return d;
    }

    // 2. CRITICAL LIMIT
    switch (device) {
        case DEV_BOILER:
            if (sensors.boiler_valid && sensors.boiler > CRITICAL_BOILER_TEMP_MAX) {
                d.criticalOk = false;
                d.reason = "CRITICAL_LIMIT";
                return d;
            }
            break;
        case DEV_ELEC_BOILER:
            if (sensors.accumulator_valid && sensors.accumulator > CRITICAL_ACCUMULATOR_TEMP_MAX) {
                d.criticalOk = false;
                d.reason = "CRITICAL_LIMIT";
                return d;
            }
            break;
        default: break;
    }

    // 3. PHASE LOSS
    if ((device == DEV_BOILER || device == DEV_ELEC_BOILER) && !phases.ok()) {
        d.phasesOk = false;
        d.reason = "PHASE_LOSS";
        return d;
    }

    // 4. MANUAL OVERRIDE
    const ManualOverride* mo = nullptr;
    switch (device) {
        case DEV_BOILER:        mo = &states.boiler_mo; break;
        case DEV_ELEC_BOILER:   mo = &states.elec_boiler_mo; break;
        case DEV_FLOOR_PUMP:    mo = &states.floor_pump_mo; break;
        case DEV_RADIATOR_PUMP: mo = &states.radiator_pump_mo; break;
    }
    if (mo && mo->active) {
        d.manualActive = true;
        d.manualState = mo->forcedState;
        d.desiredState = mo->forcedState;
        d.reason = "MANUAL_OVERRIDE";
        return d;
    }

    // 5. SCHEDULE
    if (!scheduleOk) {
        d.scheduleOk = false;
        d.reason = "SCHEDULE_OFF";
        return d;
    }


    // 6. TEMPERATURE LOGIC
    float currentTemp = 0, onThreshold = 0, offThreshold = 0;
    bool hasLogic = false;

    switch (device) {
        case DEV_BOILER:
            currentTemp = sensors.boiler;
            onThreshold = settings.boiler_threshold_on;
            offThreshold = settings.boiler_threshold_off;
            hasLogic = true;
            break;
        case DEV_ELEC_BOILER:
            currentTemp = sensors.accumulator;
            onThreshold = settings.TA_target_on;
            offThreshold = settings.TA_target_off;
            hasLogic = true;
            break;
        case DEV_FLOOR_PUMP:
            currentTemp = sensors.floor;
            onThreshold = settings.floor_threshold_on;
            offThreshold = settings.floor_threshold_off;
            hasLogic = true;
            break;
        case DEV_RADIATOR_PUMP:
            currentTemp = sensors.room;
            onThreshold = settings.room_target_on;
            offThreshold = settings.room_target_off;
            hasLogic = true;
            break;
    }

    if (hasLogic) {
        bool currentState = false;
        switch (device) {
            case DEV_BOILER:        currentState = states.boiler; break;
            case DEV_ELEC_BOILER:   currentState = states.elec_boiler; break;
            case DEV_FLOOR_PUMP:    currentState = states.floor_pump; break;
            case DEV_RADIATOR_PUMP: currentState = states.radiator_pump; break;
        }

        if (!currentState && currentTemp < onThreshold) {
            d.logicOk = true;
            d.desiredState = true;
            d.reason = "TEMP_DEMAND";
        } else if (currentState && currentTemp > offThreshold) {
            d.logicOk = false;
            d.desiredState = false;
            d.reason = "TEMP_SATISFIED";
        } else {
            d.logicOk = currentState;
            d.desiredState = currentState;
            d.reason = currentState ? "HEATING" : "IDLE";
        }
    }

    return d;
}

void evaluateAllRelays(
    const SensorData& sensors,
    const PhaseStatus& phases,
    const SystemSettings& settings,
    const DeviceStates& states,
    RelayDecision decisions[DEVICE_COUNT],
    uint8_t nowH, uint8_t nowM
) {
    for (uint8_t i = 0; i < DEVICE_COUNT; i++) {
        DeviceId dev = static_cast<DeviceId>(i);
        bool scheduleOk = isScheduleActive(i, settings, nowH, nowM);
        decisions[i] = computeRelayDecision(dev, sensors, settings, states, phases, scheduleOk);
    }
}
