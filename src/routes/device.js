// src/routes/device.js
// /api/device вЂ” СЃС‚Р°С‚СѓСЃ СѓСЃС‚СЂРѕР№СЃС‚РІР°, С‚РµР»РµРјРµС‚СЂРёСЏ, sync РѕС‚ ESP32, СЂР°СЃРїРёСЃР°РЅРёРµ

const express = require('express');
const { authenticateToken, requireRole } = require('../middleware/auth');

module.exports = function createDeviceRoutes({ prisma, broadcast, authenticateDevice, isDeviceOnline }) {
  const router = express.Router();

  // РЎС‚Р°С‚СѓСЃ СѓСЃС‚СЂРѕР№СЃС‚РІР°
  router.get('/status', authenticateToken, async (req, res) => {
    try {
      const device = await prisma.device.findFirst({ orderBy: { createdAt: 'desc' } });

      if (!device) {
        return res.json({
          name: 'РќРµ РЅР°СЃС‚СЂРѕРµРЅРѕ',
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

      // Р•РґРёРЅР°СЏ РїСЂРѕРІРµСЂРєР° РѕРЅР»Р°Р№РЅР° (РїРѕСЃР»РµРґРЅРёР№ sync РјРµРЅРµРµ 2 РјРёРЅСѓС‚ РЅР°Р·Р°Рґ)
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

  // РЎС‚Р°СЂС‹Р№ СЌРЅРґРїРѕРёРЅС‚ С‚РµР»РµРјРµС‚СЂРёРё (Р°РІС‚РѕСЂРёР·Р°С†РёСЏ СѓСЃС‚СЂРѕР№СЃС‚РІР°)
  router.post('/telemetry', authenticateDevice, async (req, res) => {
    try {
      const { serialNumber, data } = req.body || {};

      if (!serialNumber || typeof data !== 'object' || data === null) {
        return res.status(400).json({ error: 'РќСѓР¶РЅС‹ РїРѕР»СЏ serialNumber Рё data (РѕР±СЉРµРєС‚)' });
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

      broadcastToUsers({ type: 'telemetry_updated', data });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // ============================================
  // ESP32 SYNC API — Приём данных от ESP32
  // ============================================
  router.post('/sync', authenticateDevice, async (req, res) => {
    try {
      const { deviceId, uptime, firmware, settings, telemetry, device_status, phases, events } = req.body || {};

      console.log(`📥 Sync from ${deviceId || 'unknown'} at ${new Date().toISOString()}`);

      // 1. Обновить кэш последних данных
      const cache = await prisma.deviceCache.upsert({
        where: { deviceId: deviceId || 'ESP32-001' },
        update: {
          settings: settings || undefined,
          telemetry: telemetry || undefined,
          deviceStatus: device_status || undefined,
          phases: phases || undefined,
          lastSync: new Date(),
          uptime,
          firmware,
        },
        create: {
          deviceId: deviceId || 'ESP32-001',
          settings: settings || {},
          telemetry: telemetry || {},
          deviceStatus: device_status || {},
          phases: phases || {},
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

      // 6. Забрать команды из очереди для ESP32 (лимит 5 команд)
      const pendingCount = await prisma.command.count({
        where: { status: 'pending', deviceId: device?.id || 1 },
      });
      if (pendingCount > 0) {
        console.log(`[Sync] Pending commands: ${pendingCount} (sending max 5)`);
      }

      const commands = await prisma.command.findMany({
        where: { status: 'pending', deviceId: device?.id || 1 },
        orderBy: { createdAt: 'asc' },
        take: 5,
      });

      // 7. 🚀 ОТПРАВКА ОБНОВЛЕНИЯ ЧЕРЕЗ WEBSOCKET (БЕЗОПАСНО)
      if (req.broadcastToUsers) {
        req.broadcastToUsers('device_sync', {
          deviceId,
          telemetry,
          device_status,
          timestamp: Date.now(),
        });
      }

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

  // ESP32 РїРѕРґС‚РІРµСЂР¶РґР°РµС‚ РІС‹РїРѕР»РЅРµРЅРёРµ РєРѕРјР°РЅРґС‹
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
            message: `РљРѕРјР°РЅРґР° #${commandId} РѕС‚РєР»РѕРЅРµРЅР°: ${message || 'РЅРµРёР·РІРµСЃС‚РЅР°СЏ РѕС€РёР±РєР°'}`,
          },
        });
      } else {
        await prisma.event.create({
          data: {
            eventType: 'INFO',
            message: `РљРѕРјР°РЅРґР° #${commandId} (${command.command}) РІС‹РїРѕР»РЅРµРЅР°: ${message || 'OK'}`,
          },
        });
      }

      // РЎС‚Р°С‚СѓСЃС‹ СѓСЃС‚СЂРѕР№СЃС‚РІ РјРѕРіР»Рё РёР·РјРµРЅРёС‚СЊСЃСЏ вЂ” РґР°С‘Рј Р·РЅР°С‚СЊ РёРЅС‚РµСЂС„РµР№СЃСѓ
      broadcastToUsers({ type: 'device_status_updated' });

      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // ============================================
  // RASPIsanie (Schedule) API вЂ” СѓРїСЂР°РІР»РµРЅРёРµ СЂР°СЃРїРёСЃР°РЅРёРµРј ESP32
  // ============================================

  // GET /api/device/schedule — прочитать текущее расписание из cache
  router.get('/schedule', authenticateToken, requireRole('ADMIN', 'OPERATOR'), async (req, res) => {
    try {
      const device = await prisma.device.findFirst({ orderBy: { createdAt: 'desc' } });
      if (!device) {
        return res.status(404).json({ error: 'Device not configured' });
      }

      const cache = await prisma.deviceCache.findFirst({
        where: { deviceId: device.serialNumber || 'ESP32-001' },
        orderBy: { lastSync: 'desc' },
      });

      const online = await isDeviceOnline();

      // 🛑 FIX: показываем фронту, есть ли неподтверждённое изменение в очереди
      const pendingCmd = await prisma.command.findFirst({
        where: { deviceId: device.id, command: 'SET_SCHEDULE', status: 'pending' },
        orderBy: { createdAt: 'desc' },
      });

      const scheduleData = cache && cache.settings ? cache.settings.schedule : null;

      if (scheduleData) {
        const formatted = [];
        for (let i = 0; i < 4; i++) {
          const sched = scheduleData[i] || scheduleData[String(i)];
          if (sched) {
            formatted.push({
              deviceId: i,
              enabled: Boolean(sched.enabled),
              slots: (sched.slots || []).map((slot) => ({
                enabled: Boolean(slot.enabled),
                startH: Number(slot.startH) || 0,
                startM: Number(slot.startM) || 0,
                endH: Number(slot.endH) || 0,
                endM: Number(slot.endM) || 0,
              })),
            });
          }
        }
        res.json({
          schedule: formatted,
          lastSync: cache.lastSync,
          online,
          pendingUpdate: pendingCmd ? pendingCmd.payload : null,
        });
      } else {
        res.json({
          schedule: [],
          lastSync: cache ? cache.lastSync : null,
          online,
          pendingUpdate: pendingCmd ? pendingCmd.payload : null,
          message: 'No data - requesting schedule from ESP32',
        });
      }
    } catch (error) {
      console.error('[Schedule] Error reading schedule:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // POST /api/device/schedule/request — запросить актуальное расписание у ESP32
  router.post('/schedule/request', authenticateToken, requireRole('ADMIN', 'OPERATOR'), async (req, res) => {
    try {
      const device = await prisma.device.findFirst({ orderBy: { createdAt: 'desc' } });
      if (!device) {
        return res.status(404).json({ error: 'Device not configured' });
      }

      const online = await isDeviceOnline();
      if (!online) {
        return res.status(400).json({
          error: 'ESP32 offline',
          message: 'Request cannot be sent',
        });
      }

      // 🛑 FIX: не накапливаем дубликаты GET_SCHEDULE в очереди
      const existing = await prisma.command.findFirst({
        where: { deviceId: device.id, command: 'GET_SCHEDULE', status: 'pending' },
      });
      if (existing) {
        return res.json({
          success: true,
          message: 'Request already queued, data will refresh on next sync',
        });
      }

      await prisma.command.create({
        data: {
          deviceId: device.id,
          command: 'GET_SCHEDULE',
          payload: {},
          status: 'pending',
        },
      });

      console.log('[Schedule] GET_SCHEDULE request queued for ESP32');

      res.json({
        success: true,
        message: 'Request sent. Data will refresh on next sync.',
      });
    } catch (error) {
      console.error('[Schedule] Error requesting schedule:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // POST /api/device/schedule/save — сохранить изменения расписания
  router.post('/schedule/save', authenticateToken, requireRole('ADMIN', 'OPERATOR'), async (req, res) => {
    try {
      const { deviceId, slots } = req.body || {};

      // Валидация input
      if (deviceId === undefined || deviceId === null || ![0, 1, 2, 3].includes(deviceId)) {
        return res.status(400).json({ error: 'Invalid deviceId. Allowed: 0-3' });
      }

      if (!Array.isArray(slots) || slots.length !== 4) {
        return res.status(400).json({ error: 'slots must contain exactly 4 elements' });
      }

      // Нормализация и валидация каждого слота
      const cleanSlots = slots.map((s) => {
        const toInt = (v, max) => {
          const n = parseInt(v, 10);
          if (!Number.isFinite(n)) return 0;
          return Math.min(Math.max(n, 0), max);
        };
        return {
          enabled: Boolean(s && s.enabled),
          startH: toInt(s && s.startH, 23),
          startM: toInt(s && s.startM, 59),
          endH: toInt(s && s.endH, 23),
          endM: toInt(s && s.endM, 59),
        };
      });

      // Проверка онлайна ESP32
      const online = await isDeviceOnline();
      if (!online) {
        return res.status(400).json({
          error: 'ESP32 offline',
          message: 'Save impossible: device is offline',
        });
      }

      const device = await prisma.device.findFirst({ orderBy: { createdAt: 'desc' } });
      if (!device) {
        return res.status(404).json({ error: 'Device not configured' });
      }

      // 🛑 FIX #1: удаляем СТАРЫЕ неподтверждённые команды расписания.
      // ESP32 всегда получит только ОДНУ свежую команду (маленький JSON = надёжный парсинг).
      const removed = await prisma.command.deleteMany({
        where: {
          deviceId: device.id,
          status: 'pending',
          command: { in: ['SET_SCHEDULE', 'GET_SCHEDULE'] },
        },
      });
      if (removed.count > 0) {
        console.log(`[Schedule] Superseded ${removed.count} pending schedule command(s)`);
      }

      // Создаём ЕДИНСТВЕННУЮ команду SET_SCHEDULE для ESP32
      const cmd = await prisma.command.create({
        data: {
          deviceId: device.id,
          command: 'SET_SCHEDULE',
          payload: { deviceId, slots: cleanSlots },
          status: 'pending',
        },
      });

      console.log(`[Schedule] SET_SCHEDULE #${cmd.id} queued for device ${deviceId}:`,
        JSON.stringify(cleanSlots));

      //  НОВОЕ: МГНОВЕННАЯ ОТПРАВКА ЧЕРЕЗ WEBSOCKET
      // Отправляем команду ESP32 через WebSocket (если функция доступна)
      if (req.broadcastToDevice) {
        req.broadcastToDevice('command:new', {
          commandId: cmd.id,
          command: 'SET_SCHEDULE',
          payload: { deviceId, slots: cleanSlots }
        });
        console.log(`[WS] 📡 Sent SET_SCHEDULE to ESP32 via WebSocket`);
      }

      // Уведомляем фронтенд об обновлении расписания
      if (req.broadcastToUsers) {
        req.broadcastToUsers('schedule:updated', { deviceId, slots: cleanSlots });
        console.log(`[WS] 👥 Notified frontend about schedule update`);
      }

      // Логируем событие
      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Schedule for device #${deviceId} updated by ${req.user.username}`,
        },
      });

      res.json({
        success: true,
        message: 'Schedule save command sent to ESP32 via WebSocket',
        commandId: cmd.id,
      });
    } catch (error) {
      console.error('[Schedule] Error saving schedule:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};

