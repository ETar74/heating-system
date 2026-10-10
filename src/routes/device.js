// src/routes/device.js
// /api/device — статус устройства, телеметрия, sync от ESP32

const express = require('express');
const { authenticateToken } = require('../middleware/auth');

module.exports = function createDeviceRoutes({ prisma, broadcast, authenticateDevice, isDeviceOnline }) {
  const router = express.Router();

  // Статус устройства
  router.get('/status', authenticateToken, async (req, res) => {
    try {
      const device = await prisma.device.findFirst({ orderBy: { createdAt: 'desc' } });

      if (!device) {
        return res.json({
          name: 'Не настроено',
          online: false,
          lastSeen: null,
          deviceStatus: {},
          uptime: null,
          firmware: null,
        });
      }

      const cache = await prisma.deviceCache.findFirst({
        where: { deviceId: device.serialNumber || 'ESP32-001' },
      });

      // Единая проверка онлайна (последний sync менее 2 минут назад)
      const isOnline = await isDeviceOnline();

      res.json({
        name: device.name,
        online: isOnline,
        lastSeen: device.lastSeen,
        deviceStatus: cache?.deviceStatus || {},
        uptime: cache?.uptime,
        firmware: cache?.firmware || device.firmwareVersion,
        lastSync: cache?.lastSync,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Старый эндпоинт телеметрии (авторизация устройства)
  router.post('/telemetry', authenticateDevice, async (req, res) => {
    try {
      const { serialNumber, data } = req.body || {};

      if (!serialNumber || typeof data !== 'object' || data === null) {
        return res.status(400).json({ error: 'Нужны поля serialNumber и data (объект)' });
      }

      let device = await prisma.device.findUnique({
        where: { serialNumber },
      });

      if (!device) {
        device = await prisma.device.create({
          data: {
            name: `ESP32-${serialNumber}`,
            serialNumber,
            online: true,
            lastSeen: new Date(),
          },
        });
      } else {
        await prisma.device.update({
          where: { id: device.id },
          data: { online: true, lastSeen: new Date() },
        });
      }

      for (const [parameter, value] of Object.entries(data)) {
        await prisma.telemetry.create({
          data: {
            deviceId: device.id,
            parameter,
            value: String(value),
          },
        });
      }

      broadcast({ type: 'telemetry_updated', data });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // ============================================
  // ESP32 SYNC API — приём данных от ESP32
  // ============================================
  router.post('/sync', authenticateDevice, async (req, res) => {
    try {
      const { deviceId, uptime, firmware, settings, telemetry, device_status, events } =
        req.body || {};

      console.log(`📡 Sync from ${deviceId || 'unknown'} at ${new Date().toISOString()}`);

      // 1. Обновить кэш последних данных
      const cache = await prisma.deviceCache.upsert({
        where: { deviceId: deviceId || 'ESP32-001' },
        update: {
          settings: settings || undefined,
          telemetry: telemetry || undefined,
          deviceStatus: device_status || undefined,
          phases: req.body.phases || undefined,
          lastSync: new Date(),
          uptime,
          firmware,
        },
        create: {
          deviceId: deviceId || 'ESP32-001',
          settings: settings || {},
          telemetry: telemetry || {},
          deviceStatus: device_status || {},
          phases: req.body.phases || {},
          lastSync: new Date(),
          uptime,
          firmware,
        },
      });

      // 2. Сохранить настройки из ESP32 в таблицу parameters
      if (settings && typeof settings === 'object') {
        for (const [key, value] of Object.entries(settings)) {
          if (key && value !== undefined && value !== null) {
            try {
              await prisma.parameter.upsert({
                where: { key },
                update: { value: String(value), updatedAt: new Date() },
                create: {
                  key,
                  value: String(value),
                  description: 'Synced from ESP32',
                  updatedAt: new Date(),
                },
              });
            } catch (err) {
              console.error(`⚠️ Failed to save setting ${key}:`, err.message);
            }
          }
        }
        console.log(`💾 Saved ${Object.keys(settings).length} settings from ESP32 to DB`);
      }

      // 3. Обновить статус устройства в таблице Device
      const device = await prisma.device.findFirst({
        where: { serialNumber: deviceId },
      });

      if (device) {
        await prisma.device.update({
          where: { id: device.id },
          data: {
            online: true,
            lastSeen: new Date(),
            firmwareVersion: firmware,
          },
        });
      }

      // 4. Сохранить события в историю (dedup по lastEventId)
      if (events && Array.isArray(events) && events.length > 0) {
        let lastEventId = cache.lastEventId || 0;
        let savedCount = 0;

        for (const event of events) {
          const eventId = Number(event.id);
          if (Number.isFinite(eventId)) {
            if (eventId <= lastEventId) continue; // уже обработано
            lastEventId = Math.max(lastEventId, eventId);
          }

          await prisma.event.create({
            data: {
              deviceId: device?.id,
              eventType: event.type,
              message: event.message,
            },
          });
          savedCount++;
        }

        if (savedCount > 0) {
          await prisma.deviceCache.update({
            where: { id: cache.id },
            data: { lastEventId },
          });
        }
      }

      // 5. Сохранить телеметрию в историю (для графиков)
      if (telemetry && device) {
        for (const [parameter, value] of Object.entries(telemetry)) {
          await prisma.telemetry.create({
            data: {
              deviceId: device.id,
              parameter,
              value: String(value),
            },
          });
        }
      }

      // 6. Забрать команды из очереди для ESP32
      const commands = await prisma.command.findMany({
        where: { status: 'pending', deviceId: device?.id || 1 },
        orderBy: { createdAt: 'asc' },
      });

      // Do not change status here; ESP32 will fetch pending commands and confirm execution.

      // 7. Отправить обновление через WebSocket клиентам
      broadcast({
        type: 'device_sync',
        deviceId,
        telemetry,
        device_status,
        timestamp: Date.now(),
      });

      // 8. OTA: есть ли одобренная прошивка новой версии?
      let otaInfo = null;
      const approvedFirmware = await prisma.firmware.findFirst({
        where: { approved: true },
        orderBy: { uploadedAt: 'desc' },
      });

      if (approvedFirmware && firmware !== approvedFirmware.version) {
        const otaToken = process.env.ESP32_TOKEN
          ? `?token=${encodeURIComponent(process.env.ESP32_TOKEN)}`
          : '';
        otaInfo = {
          available: true,
          version: approvedFirmware.version,
          url: `http://${req.headers.host}/api/ota/download/${approvedFirmware.id}${otaToken}`,
          size: approvedFirmware.filesize,
          md5: approvedFirmware.md5,
        };
        console.log(`🔄 OTA Update available for ${deviceId}: v${approvedFirmware.version}`);
      }

      res.json({
        success: true,
        serverTime: Math.floor(Date.now() / 1000),
        commands: commands.map((cmd) => ({
          id: cmd.id,
          type: cmd.command,
          payload: cmd.payload,
          createdAt: cmd.createdAt.getTime(),
        })),
        ota: otaInfo,
      });
    } catch (error) {
      console.error('❌ Error in /api/device/sync:', error);
      if (!res.headersSent) {
        res.status(500).json({ error: error.message });
      }
    }
  });

  // ESP32 подтверждает выполнение команды
  router.post('/command/:id/executed', authenticateDevice, async (req, res) => {
    try {
      const commandId = parseInt(req.params.id, 10);
      const { success, message } = req.body || {};

      const command = await prisma.command.update({
        where: { id: commandId },
        data: {
          status: success === false ? 'failed' : 'executed',
          executedAt: new Date(),
        },
      });

      if (success === false) {
        await prisma.event.create({
          data: {
            eventType: 'ERROR',
            message: `Команда #${commandId} отклонена: ${message || 'неизвестная ошибка'}`,
          },
        });
      } else {
        await prisma.event.create({
          data: {
            eventType: 'INFO',
            message: `Команда #${commandId} (${command.command}) выполнена: ${message || 'OK'}`,
          },
        });
      }

      // Статусы устройств могли измениться — даём знать интерфейсу
      broadcast({ type: 'device_status_updated' });

      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
