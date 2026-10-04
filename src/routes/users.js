// src/routes/users.js
// /api/users — управление пользователями (только ADMIN)

const express = require('express');
const bcrypt = require('bcryptjs');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { redeemCode } = require('../lib/bindCodes');

const USERNAME_RE = /^[a-zA-Z0-9_.-]{2,32}$/;

function parseTelegramId(value) {
  // Возвращает { ok: true, value: BigInt|null } или { ok: false, error }
  if (value === null || value === undefined || value === '') {
    return { ok: true, value: null };
  }
  try {
    const asBig = BigInt(String(value).trim());
    if (asBig <= 0n || asBig > 1000000000000n) throw new Error('out of range');
    return { ok: true, value: asBig };
  } catch (e) {
    return { ok: false, error: 'Некорректный Telegram ID' };
  }
}

module.exports = function createUsersRoutes({ prisma, bot }) {
  const router = express.Router();

  router.get('/', authenticateToken, requireRole('ADMIN'), async (req, res) => {
    try {
      const users = await prisma.user.findMany({ include: { role: true } });
      res.json(
        users.map((u) => ({
          id: u.id,
          username: u.username,
          role: u.role.name,
          telegramId: u.telegramId?.toString(),
          createdAt: u.createdAt,
        }))
      );
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  router.post('/', authenticateToken, requireRole('ADMIN'), async (req, res) => {
    try {
      const { username, password, role, telegramId } = req.body || {};

      if (!username || !USERNAME_RE.test(username)) {
        return res
          .status(400)
          .json({ error: 'Логин: 2–32 символа, только буквы, цифры, _ . -' });
      }
      if (!password || password.length < 4) {
        return res.status(400).json({ error: 'Пароль: минимум 4 символа' });
      }

      const roleRecord = await prisma.role.findUnique({ where: { name: role } });
      if (!roleRecord) {
        return res.status(400).json({ error: 'Invalid role' });
      }

      const parsedTelegram = parseTelegramId(telegramId);
      if (!parsedTelegram.ok) {
        return res.status(400).json({ error: parsedTelegram.error });
      }

      const passwordHash = await bcrypt.hash(password, 10);

      const user = await prisma.user.create({
        data: {
          username,
          passwordHash,
          roleId: roleRecord.id,
          telegramId: parsedTelegram.value,
        },
        include: { role: true },
      });

      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Пользователь ${username} создан (${req.user.username})`,
        },
      });

      res.json({ id: user.id, username: user.username, role: user.role.name });
    } catch (error) {
      if (error.code === 'P2002') {
        return res.status(409).json({ error: 'Пользователь с таким логином уже существует' });
      }
      res.status(500).json({ error: error.message });
    }
  });

  router.put('/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
    try {
      const { username, password, role, telegramId } = req.body || {};
      const userId = parseInt(req.params.id, 10);
      if (!userId) return res.status(400).json({ error: 'Некорректный ID пользователя' });

      // Не даём понизить последнего администратора
      if (role && role !== 'ADMIN') {
        const target = await prisma.user.findUnique({
          where: { id: userId },
          include: { role: true },
        });
        if (target && target.role.name === 'ADMIN') {
          const adminsCount = await prisma.user.count({ where: { roleId: target.roleId } });
          if (adminsCount <= 1) {
            return res.status(400).json({ error: 'Нельзя сменить роль последнего администратора' });
          }
        }
      }

      const updateData = {};
      if (username !== undefined) {
        if (!USERNAME_RE.test(username)) {
          return res.status(400).json({ error: 'Логин: 2–32 символа, только буквы, цифры, _ . -' });
        }
        updateData.username = username;
      }
      if (password) {
        updateData.passwordHash = await bcrypt.hash(password, 10);
      }
      if (telegramId !== undefined) {
        const parsedTelegram = parseTelegramId(telegramId);
        if (!parsedTelegram.ok) {
          return res.status(400).json({ error: parsedTelegram.error });
        }
        updateData.telegramId = parsedTelegram.value;
      }
      if (role) {
        const roleRecord = await prisma.role.findUnique({ where: { name: role } });
        if (!roleRecord) {
          return res.status(400).json({ error: 'Invalid role' });
        }
        updateData.roleId = roleRecord.id;
      }

      const user = await prisma.user.update({
        where: { id: userId },
        data: updateData,
        include: { role: true },
      });

      res.json({ id: user.id, username: user.username, role: user.role.name });
    } catch (error) {
      if (error.code === 'P2002') {
        return res.status(409).json({ error: 'Пользователь с таким логином уже существует' });
      }
      res.status(500).json({ error: error.message });
    }
  });

  router.delete('/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
    try {
      const userId = parseInt(req.params.id, 10);
      if (!userId) return res.status(400).json({ error: 'Некорректный ID пользователя' });

      if (userId === req.user.id) {
        return res.status(400).json({ error: 'Нельзя удалить собственный аккаунт' });
      }

      const target = await prisma.user.findUnique({
        where: { id: userId },
        include: { role: true },
      });
      if (!target) return res.status(404).json({ error: 'Пользователь не найден' });

      if (target.role.name === 'ADMIN') {
        const adminsCount = await prisma.user.count({ where: { roleId: target.roleId } });
        if (adminsCount <= 1) {
          return res.status(400).json({ error: 'Нельзя удалить последнего администратора' });
        }
      }

      await prisma.user.delete({ where: { id: userId } });
      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Пользователь ${target.username} удалён (${req.user.username})`,
        },
      });
      res.json({ message: 'User deleted' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Привязка Telegram: админ вводит код, который пользователь получил командой /bind в боте
  router.post('/:id/bind', authenticateToken, requireRole('ADMIN'), async (req, res) => {
    try {
      const userId = parseInt(req.params.id, 10);
      if (!userId) return res.status(400).json({ error: 'Некорректный ID пользователя' });

      const { code } = req.body || {};
      const entry = redeemCode(code);
      if (!entry) {
        return res.status(400).json({ error: 'Код не найден или истёк (действует 10 минут)' });
      }

      const user = await prisma.user.update({
        where: { id: userId },
        data: { telegramId: entry.telegramId },
        include: { role: true },
      });

      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Telegram привязан к пользователю ${user.username} (${req.user.username})`,
        },
      });

      if (bot) {
        try {
          await bot.sendMessage(
            entry.telegramId.toString(),
            '✅ Ваш Telegram привязан к аккаунту. Команды бота теперь доступны.'
          );
        } catch (err) {
          console.error('Bind confirmation failed:', err.message);
        }
      }

      res.json({ success: true, telegramId: entry.telegramId.toString() });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
