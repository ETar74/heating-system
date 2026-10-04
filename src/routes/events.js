// src/routes/events.js
// /api/events — журнал событий

const express = require('express');
const { authenticateToken } = require('../middleware/auth');

module.exports = function createEventsRoutes({ prisma }) {
  const router = express.Router();

  router.get('/', authenticateToken, async (req, res) => {
    try {
      const limit = Math.min(parseInt(req.query.limit, 10) || 100, 1000);
      const events = await prisma.event.findMany({
        orderBy: { createdAt: 'desc' },
        take: limit,
      });
      res.json(events);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};