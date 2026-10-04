// src/routes/auth.js
// /api/auth — логин, logout, текущий пользователь

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { authenticateToken } = require('../middleware/auth');
const { rateLimit } = require('../middleware/rateLimit');

module.exports = function createAuthRoutes({ prisma }) {
  const router = express.Router();

  // Rate limit защищает от брут-форса
  router.post('/login', rateLimit({ windowMs: 15 * 60 * 1000, max: 15 }), async (req, res) => {
    try {
      const { username, password } = req.body || {};

      if (!username || !password) {
        return res.status(400).json({ error: 'Укажите логин и пароль' });
      }

      const user = await prisma.user.findUnique({
        where: { username },
        include: { role: true },
      });

      if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const validPassword = await bcrypt.compare(password, user.passwordHash);
      if (!validPassword) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const token = jwt.sign(
        { id: user.id, username: user.username, role: user.role.name },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );

      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Пользователь ${username} вошёл в систему`,
        },
      });

      res.json({ token, user: { id: user.id, username: user.username, role: user.role.name } });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  router.post('/logout', authenticateToken, async (req, res) => {
    try {
      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Пользователь ${req.user.username} вышел из системы`,
        },
      });
      res.json({ message: 'Logged out successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  router.get('/me', authenticateToken, async (req, res) => {
    try {
      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
        include: { role: true },
      });
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json({ id: user.id, username: user.username, role: user.role.name });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};