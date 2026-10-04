// src/lib/settingsSchema.js
// Валидация настроек: тип, допустимые диапазоны.
// Защита системы от опасных значений (например, целевая температура 500 °C).

const TIME_RE = /^([01]?\d|2[0-3]):[0-5]\d$/;

const SCHEMA = {
  // Помещение
  room_temp_target: { min: 15, max: 30 },
  room_temp_threshold_on: { min: 10, max: 35 },
  room_temp_threshold_off: { min: 10, max: 35 },
  room_temp_hysteresis: { min: 0, max: 5 },

  // Котёл
  boiler_temp_target: { min: 40, max: 90 },
  boiler_temp_threshold_on: { min: 30, max: 95 },
  boiler_temp_threshold_off: { min: 30, max: 95 },
  boiler_temp_hysteresis: { min: 0, max: 10 },

  // Тёплые полы
  floor_temp_target: { min: 18, max: 35 },
  floor_temp_threshold_on: { min: 15, max: 40 },
  floor_temp_threshold_off: { min: 15, max: 40 },
  floor_temp_hysteresis: { min: 0, max: 5 },

  // Теплоаккумулятор
  accumulator_temp_target: { min: 40, max: 85 },
  accumulator_temp_threshold_on: { min: 30, max: 95 },
  accumulator_temp_threshold_off: { min: 30, max: 95 },
  accumulator_temp_hysteresis: { min: 0, max: 10 },

  // Режимы
  night_start: { time: true },
  night_end: { time: true },
  manual_timeout: { min: 5, max: 3600, integer: true },
};

/**
 * Проверяет значение настройки.
 * @returns {{ valid: true, value: number|string } | { valid: false, error: string }}
 */
function validateSetting(key, value) {
  const rule = SCHEMA[key];
  if (!rule) {
    return { valid: false, error: `Неизвестный параметр "${key}"` };
  }

  if (rule.time) {
    const s = String(value ?? '').trim();
    if (!TIME_RE.test(s)) {
      return { valid: false, error: `Параметр "${key}": ожидается время в формате ЧЧ:ММ` };
    }
    return { valid: true, value: s };
  }

  if (value === undefined || value === null || value === '') {
    return { valid: false, error: `Параметр "${key}": значение не может быть пустым` };
  }
  const num = Number(value);
  if (Number.isNaN(num)) {
    return { valid: false, error: `Параметр "${key}": значение должно быть числом` };
  }
  if (rule.integer && !Number.isInteger(num)) {
    return { valid: false, error: `Параметр "${key}": значение должно быть целым числом` };
  }
  if (num < rule.min || num > rule.max) {
    return {
      valid: false,
      error: `Параметр "${key}": значение ${num} вне допустимого диапазона ${rule.min}–${rule.max}`,
    };
  }

  return { valid: true, value: num };
}

module.exports = { validateSetting, SCHEMA };