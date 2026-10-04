// src/lib/alarms.js
// Алерты системы: офлайн устройства, потеря фаз, неисправные датчики,
// нештатное давление в системе.
//
// Дросселирование: повторное уведомление по одному ключу не чаще раза в час.
// При исчезновении алерта отправляется INFO о восстановлении.

const OFFLINE_AFTER_MS = 5 * 60 * 1000; // офлайн — если нет синка дольше 5 минут
const REPEAT_AFTER_MS = 60 * 60 * 1000; // повтор алерта каждый час
const PRESSURE_MIN = 0.8;
const PRESSURE_MAX = 3.0;
const SENSOR_FAULT_MAX = -127;

class AlarmEngine {
  constructor({ prisma, notify }) {
    this.prisma = prisma;
    this.notify = notify; // (type, message) => Promise
    this.active = new Map(); // key -> { lastNotifiedAt }
  }

  async check() {
    const cache = await this.prisma.deviceCache.findFirst({
      orderBy: { lastSync: 'desc' },
    });

    const alarms = [];

    // 1. Устройство офлайн
    const offline =
      !cache ||
      !cache.lastSync ||
      Date.now() - cache.lastSync.getTime() > OFFLINE_AFTER_MS;
    if (offline) {
      alarms.push({
        key: 'device_offline',
        type: 'ALARM',
        message: 'Контроллер ESP32 недоступен более 5 минут',
      });
    }

    if (cache) {
      // 2. Потеря фаз
      if (cache.phases && typeof cache.phases === 'object') {
        const lost = ['L1', 'L2', 'L3'].filter((p) => !cache.phases[p]);
        if (lost.length > 0) {
          alarms.push({
            key: `phases_lost:${lost.join('+')}`,
            type: 'WARNING',
            message: `Потеря фаз питания: ${lost.join(', ')}`,
          });
        }
      }

      // 3. Неисправные датчики
      if (cache.telemetry && typeof cache.telemetry === 'object') {
        for (const [key, rawValue] of Object.entries(cache.telemetry)) {
          const value = parseFloat(rawValue);
          if (!Number.isNaN(value) && value <= SENSOR_FAULT_MAX) {
            alarms.push({
              key: `sensor_fault:${key}`,
              type: 'WARNING',
              message: `Неисправен датчик (${key}): значение ${value}`,
            });
          }
        }

        // 4. Давление в системе
        const pressure = parseFloat(cache.telemetry.pressure);
        if (!Number.isNaN(pressure) && (pressure < PRESSURE_MIN || pressure > PRESSURE_MAX)) {
          alarms.push({
            key: 'pressure_out_of_range',
            type: 'WARNING',
            message: `Нештатное давление в системе: ${pressure} бар (норма ${PRESSURE_MIN}–${PRESSURE_MAX})`,
          });
        }
      }
    }

    this.apply(alarms);
  }

  apply(alarms) {
    const now = Date.now();
    const seenKeys = new Set(alarms.map((a) => a.key));

    for (const alarm of alarms) {
      const info = this.active.get(alarm.key);
      if (!info) {
        this.active.set(alarm.key, { lastNotifiedAt: now });
        this.send(alarm);
      } else if (now - info.lastNotifiedAt > REPEAT_AFTER_MS) {
        info.lastNotifiedAt = now;
        this.send(alarm);
      }
    }

    // Восстановление: алерты, которых больше нет
    for (const [key, info] of this.active) {
      if (!seenKeys.has(key)) {
        this.active.delete(key);
        this.notify('INFO', `Восстановлено: алерт "${key}" снят`).catch((err) => {
          console.error('Recovery notification error:', err.message);
        });
      }
    }
  }

  send(alarm) {
    this.notify(alarm.type, alarm.message).catch((err) => {
      console.error('Alarm notification error:', err.message);
    });
  }
}

module.exports = { AlarmEngine };