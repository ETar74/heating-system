// control_io.cpp — Аппаратный слой (HAL)
// Только: GPIO (digitalWrite), NVS (storage), ADC (фазы)
// НЕТ бизнес-логики, гистерезиса, расписания

#include "control_io.h"
#include "storage.h"
#include <Arduino.h>

ControlIO controlIO;

void ControlIO::begin() {
    // Инициализация GPIO реле
    for (uint8_t i = 0; i < DEVICE_COUNT; i++) {
        pinMode(relayPins[i], OUTPUT);
        digitalWrite(relayPins[i], LOW);  // FAIL-SAFE: принудительно OFF при старте
    }
    
    // Входы
    pinMode(PIN_PHASE_SENSOR, INPUT);
    pinMode(PIN_BUTTON_CALIB, INPUT_PULLUP);
    
    Serial.println("[ControlIO] Initialized (Fail-Safe: all relays OFF)");
}

void ControlIO::applyRelayDecision(DeviceId device, const RelayDecision& decision) {
    if (device >= DEVICE_COUNT) return;
    
    // Маппинг устройства -> ссылка на состояние в DeviceStates
    // Это делается через callback или прямое обращение в control.cpp
    // Здесь только GPIO + лог
    
    // Лог решения (аудит)
    #if DEBUG_SCHEDULE
    Serial.printf("[Interlock] Dev=%d: %s -> %s | Reason: %s | S=%d L=%d M=%d C=%d Sch=%d Ph=%d\n",
                  device,
                  decision.desiredState ? "ON" : "OFF",  // desiredState уже итоговое
                  decision.desiredState ? "ON" : "OFF",
                  decision.reason,
                  decision.sensorOk, decision.logicOk, decision.manualActive,
                  decision.criticalOk, decision.scheduleOk, decision.phasesOk);
    #endif
    // GPIO записывается в control.cpp через setDeviceState -> setBoiler() etc
    // Этот метод вызывается ПОСЛЕ того как control.cpp обновил states.xxx
}

// Прямые сеттеры для API (manual override, emergency stop)
void ControlIO::setBoiler(bool state) {
    updateRelay(PIN_RELAY_BOILER, const_cast<bool&>(reinterpret_cast<const bool&>(state)), state, "BOILER");
    // Примечание: реальное состояние хранится в Control::states, здесь только GPIO
    digitalWrite(PIN_RELAY_BOILER, state);
}

void ControlIO::setElecBoiler(bool state) {
    digitalWrite(PIN_RELAY_ELEC, state);
}

void ControlIO::setFloorPump(bool state) {
    digitalWrite(PIN_RELAY_FLOOR, state);
}

void ControlIO::setRadiatorPump(bool state) {
    digitalWrite(PIN_RELAY_RADIATOR, state);
}

void ControlIO::saveDeviceStates(const DeviceStates& states) {
    storage.saveDeviceStates(states.boiler, states.floor_pump,
                             states.radiator_pump, states.elec_boiler);
}

void ControlIO::readPhases(bool& l1, bool& l2, bool& l3) {
    // 8-sample averaging for noise immunity
    long sum = 0;
    for (int i = 0; i < 8; i++) {
        sum += analogRead(PIN_PHASE_SENSOR);
        delay(2);
    }
    int adc = (int)(sum / 8);

    // Original range-based decode from GitHub
    if (adc < 500) {
        l1 = false; l2 = false; l3 = false; return;
    }
    if      (adc <= 1448) { l1 = true;  l2 = true;  l3 = true;  }
    else if (adc <= 1620) { l1 = false; l2 = true;  l3 = true;  }
    else if (adc <= 1800) { l1 = true;  l2 = true;  l3 = false; }
    else if (adc <= 2080) { l1 = false; l2 = true;  l3 = false; }
    else if (adc <= 2450) { l1 = true;  l2 = false; l3 = true;  }
    else if (adc <= 2940) { l1 = false; l2 = false; l3 = true;  }
    else if (adc <= 3733) { l1 = true;  l2 = false; l3 = false; }
    else                  { l1 = false; l2 = false; l3 = false; }
}

void ControlIO::printRelayStatus() {
    Serial.print("=== RELAY STATUS: ");  
    for (uint8_t i = 0; i < DEVICE_COUNT; i++) {
        bool state = digitalRead(relayPins[i]);
        Serial.printf("%s(GPIO%d)=%s", relayNames[i], relayPins[i], state ? "ON" : "OFF");
        if (i < DEVICE_COUNT - 1) {
            Serial.print(" | ");
        }
    }
    Serial.println(" ===");
}

// Внутренний метод с проверкой изменений
void ControlIO::updateRelay(uint8_t pin, bool& currentState, bool newState, const char* name) {
    if (currentState != newState) {
        digitalWrite(pin, newState);
        currentState = newState;
        Serial.printf("[ControlIO] %s: %s\n", name, newState ? "ON" : "OFF");
    }
}