// src/middleware/deviceAuth.js
// Аутентификация запросов от устройства ESP32.
//
// Две независимые проверки (включаются через .env):
//   ESP32_TOKEN         — общий секрет устройства. ESP32 шлёт его в заголовке
//                         Authorization: Bearer <токен> или в query: ?token=<токен>
//   ESP32_ALLOWED_IPS   — список разрешённых IP через запятую
//
// Если обе настройки пусты — dev-режим: запросы проходят,
// но в лог каждые 10 минут печатается предупреждение.

const crypto = require('crypto');

let lastWarnAt = 0;

function safeEqual(a, b) {
  const ab = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  if (ab.length !== bb.length) return false;
  return crypto.timingSafeEqual(ab, bb);
}

function getClientIp(req) {
  const fwd = req.headers['x-forwarded-for'];
  if (fwd) return String(fwd).split(',')[0].trim();
  return req.socket.remoteAddress || '';
}

function authenticateDevice(req, res, next) {
  const token = process.env.ESP32_TOKEN;
  const allowedIPs = (process.env.ESP32_ALLOWED_IPS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  // Dev-режим: ничего не проверяем (с периодическим предупреждением)
  if (!token && allowedIPs.length === 0) {
    const now = Date.now();
    if (now - lastWarnAt > 10 * 60 * 1000) {
      lastWarnAt = now;
      console.warn(
        '⚠️  ESP32 device auth is DISABLED (dev mode). ' +
        'Set ESP32_TOKEN and/or ESP32_ALLOWED_IPS in .env to protect device endpoints!'
      );
    }
    return next();
  }

  // Разрешённые IP
  if (allowedIPs.length > 0) {
    const ip = getClientIp(req);
    if (!allowedIPs.includes(ip)) {
      console.warn(`🚫 Device request from forbidden IP ${ip}: ${req.method} ${req.originalUrl}`);
      return res.status(403).json({ error: 'Device IP not allowed' });
    }
  }

  // Токен устройства
  if (token) {
    const auth = req.headers['authorization'] || '';
    const fromHeader = auth.startsWith('Bearer ') ? auth.slice(7).trim() : null;
    const fromQuery = req.query && req.query.token ? String(req.query.token) : null;
    const provided = fromHeader || fromQuery;

    if (!provided || !safeEqual(provided, token)) {
      console.warn(`🚫 Device request without valid token: ${req.method} ${req.originalUrl}`);
      return res.status(401).json({ error: 'Invalid device token' });
    }
  }

  next();
}

module.exports = { authenticateDevice };