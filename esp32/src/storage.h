#ifndef STORAGE_H
#define STORAGE_H

#include <Preferences.h>
#include <DallasTemperature.h>
#include "config.h"

class Storage {
public:
    void begin();

    void loadSettings(SystemSettings &s);
    void saveSettings(const SystemSettings &s);
    
    void loadSchedule(DeviceSchedule* schedule);
    void saveSchedule(const DeviceSchedule* schedule);

    void saveSensorAddress(uint8_t role, const DeviceAddress &addr);
    bool loadSensorAddress(uint8_t role, DeviceAddress &addr);
    bool hasSensorAddress(uint8_t role);
    void removeSensorAddress(uint8_t role);
    void clearSensorAddresses();

    void saveDeviceStates(bool boiler, bool floor, bool radiator, bool elec);
    void loadDeviceStates(bool &boiler, bool &floor, bool &radiator, bool &elec);

private:
    Preferences prefs;
};

extern Storage storage;

#endif // STORAGE_H