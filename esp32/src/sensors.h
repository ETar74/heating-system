#ifndef SENSORS_H
#define SENSORS_H

#include <OneWire.h>
#include <DallasTemperature.h>
#include "config.h"

struct SensorData {
    float room = 0;
    float boiler = 0;
    float floor = 0;
    float accumulator = 0;
    float outdoor = 0;

    bool room_valid = false;
    bool boiler_valid = false;
    bool floor_valid = false;
    bool accumulator_valid = false;
    bool outdoor_valid = false;

    unsigned long lastUpdate = 0;
};

struct SensorAddresses {
    DeviceAddress room;
    DeviceAddress boiler;
    DeviceAddress floor;
    DeviceAddress accumulator;
    DeviceAddress outdoor;
    bool calibrated = false;
};

class Sensors {
public:
    void begin();
    void update();

    SensorData getData();
    bool isSensorValid(uint8_t role);
    float getTemperature(uint8_t role);
    void getAddress(uint8_t role, DeviceAddress &addr);
    int getSensorCount();

    // Калибровка (Serial + Nextion)
    void scanBus();
    int getBusCount();
    int8_t getRoleBusIndex(uint8_t role);
    void setRoleBusIndex(uint8_t role, int8_t idx);
    void cycleRoleBusIndex(uint8_t role, int8_t dir);
    float getBusTemp(uint8_t idx);
    void saveAllAddresses();

    void startCalibration();
    void assignSensorToRole(uint8_t role, uint8_t idx);
    bool isCalibrating();
    void printAllSensors();

private:
    void loadAddresses();
    float readRole(const DeviceAddress &addr, bool &valid);
    bool isValidTemperature(float temp);
    bool isZeroAddress(const DeviceAddress &addr);
    bool isOnBus(const DeviceAddress &addr);
    DeviceAddress* roleAddr(uint8_t role);

    OneWire oneWire = OneWire(PIN_ONE_WIRE);
    DallasTemperature dallas = DallasTemperature(&oneWire);

    SensorData data;
    SensorAddresses addresses;

    DeviceAddress discovered[10];
    int discoveredCount = 0;
    bool calibrating = false;
};

extern Sensors sensors;

#endif // SENSORS_H