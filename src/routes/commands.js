// src/routes/commands.js
// /api/commands — очередь команд для ESP32

const express = require('express');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { ALLOWED_COMMANDS } = require('../lib/constants');

module.exports = function createCommandsRoutes({ prisma, broadcast, authenticateDevice }) {
  const router = express.Router();

  // Поставить команду в очередь (только ALLOWED_COMMANDS!)
  router.post(
    '/',
    authenticateToken,
    requireRole('ADMIN', 'OPERATOR'),
    async (req, res) => {
      try {
        const { command, payload } = req.body || {};

        if (typeof command !== 'string' || !ALLOWED_COMMANDS.includes(command)) {
          return res.status(400).json({ error: `Команда "${command}" не разрешена` });
        }

        const device = await prisma.device.findFirst();
        if (!device) {
          return res.status(404).json({ error: 'No device configured' });
        }

        const cmd = await prisma.command.create({
          data: {
            deviceId: device.id,
            command,
            payload: payload || {},
          },
        });

        await prisma.event.create({
          data: {
            deviceId: device.id,
            eventType: 'INFO',
            message: `Команда ${command} поставлена в очередь (${req.user.username})`,
          },
        });

        broadcastToUsers({ type: 'command_queued', command: cmd });
        res.json(cmd);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    }
  );

  // Очередь для ESP32 (авторизация устройства)
  router.get('/pending', authenticateDevice, async (req, res) => {
    try {
      const commands = await prisma.command.findMany({
        where: { status: 'pending' },
        orderBy: { createdAt: 'asc' },
      });

      res.json(
        commands.map((cmd) => ({
          id: cmd.id,
          type: cmd.command,
          payload: cmd.payload,
          createdAt: cmd.createdAt.getTime(),
        }))
      );
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // 🛑 НОВОЕ: Маршрут для подтверждения выполнения команды ESP32
  router.post(
    '/:id/executed',
    authenticateDevice, // ESP32 использует этот middleware для аутентификации
    async (req, res) => {
      try {
        const commandId = parseInt(req.params.id, 10);
        const { success, message } = req.body || {};

        if (isNaN(commandId)) {
          return res.status(400).json({ error: 'Неверный ID команды' });
        }

        // Обновляем статус команды в БД
        await prisma.command.update({
          where: { id: commandId },
          data: {
            status: success ? 'executed' : 'failed',
            // Если в твоей схеме Prisma (schema.prisma) есть поле для результата/ошибки, 
            // раскомментируй строку ниже:
            // result: message || null, 
          },
        });

        console.log(`[Commands] ✅ Команда #${commandId} помечена как ${success ? 'executed' : 'failed'}`);

        res.json({ success: true, message: 'Command acknowledged' });
      } catch (error) {
        console.error(`[Commands] ❌ Ошибка подтверждения команды #${req.params.id}:`, error.message);
        res.status(500).json({ error: error.message });
      }
    }
  );

  return router; // <-- Эта строка должна быть ПОСЛЕ добавленного кода
};
