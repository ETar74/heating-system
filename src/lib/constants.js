// src/lib/constants.js
// Разрешённые команды для очереди ESP32.
// Любая другая команда отклоняется с HTTP 400.

const ALLOWED_COMMANDS = [
  'boiler_on',
  'boiler_off',
  'floor_pump_on',
  'floor_pump_off',
  'radiator_pump_on',
  'radiator_pump_off',
  'elec_boiler_on',
  'elec_boiler_off',
  'SET_SETTING',
];

module.exports = { ALLOWED_COMMANDS };