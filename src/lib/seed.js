// src/lib/seed.js
// Инициализация БД: роли, дефолтный админ, дефолтные настройки, устройство.

async function initializeDatabase(prisma) {
  try {
    const roles = ['ADMIN', 'OPERATOR', 'VIEWER'];
    for (const roleName of roles) {
      await prisma.role.upsert({
        where: { name: roleName },
        update: {},
        create: { name: roleName, description: `${roleName} role` },
      });
    }

    const adminRole = await prisma.role.findUnique({ where: { name: 'ADMIN' } });
    const existingAdmin = await prisma.user.findUnique({ where: { username: 'admin' } });

    if (!existingAdmin && adminRole) {
      const bcrypt = require('bcryptjs');
      const passwordHash = await bcrypt.hash('admin123', 10);
      await prisma.user.create({
        data: {
          username: 'admin',
          passwordHash,
          roleId: adminRole.id,
        },
      });
      console.log('Default admin user created (username: admin, password: admin123) — смените пароль!');
    }

    // Инициализация настроек по умолчанию (если их нет)
    const defaultParams = [
      { key: 'room_temp_target', value: '22.0', description: 'Целевая температура помещения' },
      { key: 'room_temp_threshold_on', value: '21.5', description: 'Порог включения отопления' },
      { key: 'room_temp_threshold_off', value: '22.5', description: 'Порог выключения отопления' },

      { key: 'boiler_temp_target', value: '60.0', description: 'Целевая температура котла' },
      { key: 'boiler_temp_threshold_on', value: '55.0', description: 'Порог включения котла' },
      { key: 'boiler_temp_threshold_off', value: '65.0', description: 'Порог выключения котла' },

      { key: 'floor_temp_target', value: '25.0', description: 'Целевая температура тёплого пола' },
      { key: 'floor_temp_threshold_on', value: '24.0', description: 'Порог включения насоса ТП' },
      { key: 'floor_temp_threshold_off', value: '26.0', description: 'Порог выключения насоса ТП' },

      { key: 'accumulator_temp_target', value: '65.0', description: 'Целевая температура ТА' },
      { key: 'accumulator_temp_threshold_on', value: '60.0', description: 'Порог включения ЭК' },
      { key: 'accumulator_temp_threshold_off', value: '70.0', description: 'Порог выключения ЭК' },

      { key: 'night_start', value: '22:00', description: 'Начало ночного режима' },
      { key: 'night_end', value: '06:00', description: 'Конец ночного режима' },
      { key: 'manual_timeout', value: '30', description: 'Таймаут ручного управления (сек)' },
    ];

    for (const param of defaultParams) {
      await prisma.parameter.upsert({
        where: { key: param.key },
        update: {},
        create: param,
      });
    }

    const existingDevice = await prisma.device.findFirst();
    if (!existingDevice) {
      await prisma.device.create({
        data: {
          name: 'ESP32-Heating-Controller',
          serialNumber: 'ESP32-001',
          online: false,
        },
      });
    }

    console.log('✅ Default parameters initialized');
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Database initialization error:', error);
  }
}

module.exports = { initializeDatabase };
