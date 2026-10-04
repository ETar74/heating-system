// src/routes/telemetry.js
// /api/telemetry — последние значения и история (графики)

const express = require('express');
const { authenticateToken } = require('../middleware/auth');

module.exports = function createTelemetryRoutes({ prisma }) {
  const router = express.Router();

  router.get('/latest', authenticateToken, async (req, res) => {
    try {
      res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');

      // Сначала кэш DeviceCache (данные от ESP32)
      const cache = await prisma.deviceCache.findFirst({
        orderBy: { lastSync: 'desc' },
      });

      if (cache && cache.telemetry) {
        const latest = {};
        for (const [parameter, value] of Object.entries(cache.telemetry)) {
          latest[parameter] = { value, timestamp: cache.lastSync };
        }
        if (cache.phases) {
          latest.phases = { value: cache.phases, timestamp: cache.lastSync };
        }
        return res.json(latest);
      }

      // Fallback: старая таблица telemetry
      const telemetry = await prisma.telemetry.findMany({
        orderBy: { timestamp: 'desc' },
        take: 100,
      });

      const latestFromDb = {};
      telemetry.forEach((t) => {
        if (!latestFromDb[t.parameter]) {
          latestFromDb[t.parameter] = { value: t.value, timestamp: t.timestamp };
        }
      });
      res.json(latestFromDb);
    } catch (error) {
      console.error('Error in /api/telemetry/latest:', error);
      res.status(500).json({ error: error.message });
    }
  });

  router.get('/history', authenticateToken, async (req, res) => {
    try {
      const { parameter } = req.query;
      const hours = Math.min(Math.max(parseFloat(req.query.hours) || 24, 1), 24 * 365);
      const limit = Math.min(parseInt(req.query.limit, 10) || 20000, 50000);
      const since = new Date(Date.now() - hours * 60 * 60 * 1000);

      const where = { timestamp: { gte: since } };
      if (parameter) where.parameter = parameter;

      // desc + take — берём НЕдавние строки, затем разворачиваем обратно
      const telemetry = await prisma.telemetry.findMany({
        where,
        orderBy: { timestamp: 'desc' },
        take: limit,
      });
      telemetry.reverse();

      res.json(telemetry);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};