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
    console.log('[AUTH] Получен POST /auth/login');
    
    try {
      const { username, password } = req.body || {};
      console.log('[AUTH] Обрабатываем данные:', { username, password });

      // Проверка данных
      if (!username || !password) {
        console.log('[AUTH] Неверные данные запроса');
        return res.status(400).json({ error: 'Укажите логин и пароль' });
      }

      // Поиск пользователя
      console.log('[AUTH] Поиск пользователя:', username);
      const user = await prisma.user.findUnique({
        where: { username },
        include: { role: true },
      });
      console.log('[AUTH] Результат поиска:', !!user);

      if (!user) {
        console.log('[AUTH] Пользователь не найден');
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Проверка пароля
      console.log('[AUTH] Проверка пароля');
      const validPassword = await bcrypt.compare(password, user.passwordHash);
      console.log('[AUTH] Пароль верен:', validPassword);
      
      if (!validPassword) {
        console.log('[AUTH] Неверный пароль');
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Генерация токена
      console.log('[AUTH] Генерация токена');
      const token = jwt.sign(
        { id: user.id, username: user.username, role: user.role.name },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );
      console.log('[AUTH] Токен сгенерирован');

      // Создание записи о событии
      console.log('[AUTH] Создание события');
      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Пользователь ${username} вошёл в систему`,
        },
      });
      console.log('[AUTH] Событие создано');

      // Отправка ответа
      console.log('[AUTH] Отправляем ответ');
      res.json({ token, user: { id: user.id, username: user.username, role: user.role.name } });
      console.log('[AUTH] Ответ отправлен');
      
    } catch (error) {
      console.error('[AUTH] Ошибка при авторизации:', error);
      res.status(500).json({ error: error.message || 'Ошибка сервера' });
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