// src/routes/settings.js
// /api/settings — чтение и изменение настроек системы

const express = require('express');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { validateSetting } = require('../lib/settingsSchema');

module.exports = function createSettingsRoutes({ prisma, broadcast, isDeviceOnline, requireDeviceOnline }) {
  const router = express.Router();

  // Middleware: проверяет key/value ДО того, как дойдёт до записи
  const validateSettingParam = (req, res, next) => {
    const validation = validateSetting(req.params.key, (req.body || {}).value);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    req.validatedSetting = validation;
    next();
  };

  // Пакетная валидация для PUT /
  const validateBatch = (req, res, next) => {
    const { parameters } = req.body || {};
    if (!Array.isArray(parameters)) {
      return res.status(400).json({ error: 'Поле "parameters" должно быть массивом' });
    }
    for (const param of parameters) {
      if (!param || !param.key || param.value === undefined) continue;
      const v = validateSetting(param.key, param.value);
      if (!v.valid) {
        return res.status(400).json({ error: v.error });
      }
    }
    next();
  };

  router.get('/', authenticateToken, async (req, res) => {
    try {
      res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');

      const cache = await prisma.deviceCache.findFirst({
        orderBy: { lastSync: 'desc' },
      });

      if (cache && cache.settings && Object.keys(cache.settings).length > 0) {
        const settings = Object.entries(cache.settings).map(([key, value]) => ({
          key,
          value: String(value),
          updatedAt: cache.lastSync,
        }));
        return res.json(settings);
      }

      // Fallback: старая таблица Parameter
      console.log('⚠️ Device cache is empty, falling back to Parameter table');
      const parameters = await prisma.parameter.findMany();
      res.json(parameters);
    } catch (error) {
      console.error('Error in GET /api/settings:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Можно ли менять настройки (ESP32 онлайн?)
  router.get('/can-edit', authenticateToken, async (req, res) => {
    try {
      const online = await isDeviceOnline();
      const cache = await prisma.deviceCache.findFirst({
        orderBy: { lastSync: 'desc' },
      });
      res.json({
        canEdit: online,
        deviceOnline: online,
        lastSync: cache?.lastSync || null,
        message: online
          ? 'Устройство подключено. Изменение настроек разрешено.'
          : 'Устройство недоступно. Изменение настроек заблокировано.',
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Одна настройка: валидация -> проверка онлайна -> команда ESP32 + кэш
  router.put(
    '/:key',
    authenticateToken,
    requireRole('ADMIN', 'OPERATOR'),
    validateSettingParam,
    requireDeviceOnline,
    async (req, res) => {
      try {
        const key = req.params.key;
        const safeValue = req.validatedSetting.value;

        const device = await prisma.device.findFirst({ orderBy: { createdAt: 'desc' } });
        if (!device) {
          return res.status(404).json({ error: 'No device configured' });
        }

        const command = await prisma.command.create({
          data: {
            deviceId: device.id,
            command: 'SET_SETTING',
            payload: { key, value: safeValue },
            status: 'pending',
          },
        });

        // Оптимистичное обновление кэша (UI сразу покажет новое значение)
        const cache = await prisma.deviceCache.findFirst({ orderBy: { lastSync: 'desc' } });
        let oldStringValue = null;
        if (cache && cache.settings && key in cache.settings) {
          oldStringValue = String(cache.settings[key]);
          const settings = { ...cache.settings };
          settings[key] = safeValue;
          await prisma.deviceCache.update({
            where: { id: cache.id },
            data: { settings },
          });
        }

        // Обратная совместимость: старая таблица Parameter
        try {
          await prisma.parameter.upsert({
            where: { key },
            update: { value: String(safeValue) },
            create: { key, value: String(safeValue) },
          });
        } catch (e) {
          // параметра может не быть в старой таблице — не критично
        }

        await prisma.event.create({
          data: {
            eventType: 'INFO',
            message:
              oldStringValue !== null
                ? `Настройка "${key}" изменена: ${oldStringValue} → ${safeValue} (${req.user.username})`
                : `Настройка "${key}" установлена: ${safeValue} (${req.user.username})`,
          },
        });

        broadcast({ type: 'settings_updated' });

        res.json({
          success: true,
          commandId: command.id,
          message: 'Команда поставлена в очередь для ESP32',
        });
      } catch (error) {
        console.error('Error updating setting:', error);
        res.status(500).json({ error: error.message });
      }
    }
  );

  // Пакетное изменение: валидация -> проверка онлайна -> N команд ESP32 + кэш
  router.put(
    '/',
    authenticateToken,
    requireRole('ADMIN', 'OPERATOR'),
    validateBatch,
    requireDeviceOnline,
    async (req, res) => {
      try {
        const { parameters } = req.body;

        const device = await prisma.device.findFirst({ orderBy: { createdAt: 'desc' } });
        if (!device) {
          return res.status(404).json({ error: 'No device configured' });
        }

        const cache = await prisma.deviceCache.findFirst({ orderBy: { lastSync: 'desc' } });
        const cacheSettings = cache && cache.settings ? { ...cache.settings } : null;

        for (const param of parameters) {
          if (!param || !param.key || param.value === undefined) continue;
          const safeValue = Number(param.value);

          await prisma.command.create({
            data: {
              deviceId: device.id,
              command: 'SET_SETTING',
              payload: { key: param.key, value: safeValue },
              status: 'pending',
            },
          });

          if (cacheSettings) cacheSettings[param.key] = safeValue;

          try {
            await prisma.parameter.upsert({
              where: { key: param.key },
              update: { value: String(safeValue) },
              create: {
                key: param.key,
                value: String(safeValue),
                description: param.description || '',
              },
            });
          } catch (e) {
            // не критично
          }
        }

        if (cache && cacheSettings) {
          await prisma.deviceCache.update({
            where: { id: cache.id },
            data: { settings: cacheSettings },
          });
        }

        await prisma.event.create({
          data: {
            eventType: 'INFO',
            message: `Настройки изменены (пакет из ${parameters.length} шт, ${req.user.username})`,
          },
        });

        broadcast({ type: 'settings_updated' });
        res.json({ message: 'Settings updated' });
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    }
  );

  return router;
};
