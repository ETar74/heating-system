// check_keys.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Ключи, которые ищет фронтенд (из Settings.jsx)
const frontendKeys = [
  'room_temp_target',
  'room_temp_threshold_on',
  'room_temp_threshold_off',
  'room_temp_hysteresis',
  'boiler_temp_target',
  'boiler_temp_threshold_on',
  'boiler_temp_threshold_off',
  'boiler_temp_hysteresis',
  'floor_temp_target',
  'floor_temp_threshold_on',
  'floor_temp_threshold_off',
  'floor_temp_hysteresis',
  'accumulator_temp_target',
  'accumulator_temp_threshold_on',
  'accumulator_temp_threshold_off',
  'accumulator_temp_hysteresis',
  'night_start',
  'night_end',
  'manual_timeout'
];

async function checkKeys() {
  console.log('=== Проверка соответствия ключей ===\n');
  
  // Получить все ключи из базы
  const dbParams = await prisma.parameter.findMany();
  const dbKeys = dbParams.map(p => p.key);
  
  console.log('📊 Ключи в базе данных:');
  dbKeys.forEach(key => console.log(`  - ${key}`));
  
  console.log('\n🎯 Ключи, которые ищет фронтенд:');
  frontendKeys.forEach(key => console.log(`  - ${key}`));
  
  console.log('\n✅ Совпадающие ключи:');
  const matching = frontendKeys.filter(key => dbKeys.includes(key));
  matching.forEach(key => console.log(`  ✅ ${key}`));
  
  console.log('\n Ключи, которые ищет фронтенд, но НЕТ в базе:');
  const missing = frontendKeys.filter(key => !dbKeys.includes(key));
  missing.forEach(key => console.log(`   ${key}`));
  
  console.log('\n⚠️ Ключи, которые есть в базе, но НЕ ищет фронтенд:');
  const extra = dbKeys.filter(key => !frontendKeys.includes(key));
  extra.forEach(key => console.log(`  ⚠️ ${key}`));
  
  console.log('\n=== Итого ===');
  console.log(`Всего в базе: ${dbKeys.length}`);
  console.log(`Ищет фронтенд: ${frontendKeys.length}`);
  console.log(`Совпадает: ${matching.length}`);
  console.log(`Не хватает: ${missing.length}`);
  console.log(`Лишних: ${extra.length}`);
  
  await prisma.$disconnect();
}

checkKeys().catch(console.error);