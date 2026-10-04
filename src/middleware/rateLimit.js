// src/middleware/rateLimit.js
// Простой in-memory rate limiter на IP (без внешних зависимостей).

function rateLimit({ windowMs = 15 * 60 * 1000, max = 5 } = {}) {
  const hits = new Map();

  // Периодически убираем просроченные записи
  const timer = setInterval(() => {
    const now = Date.now();
    for (const [key, rec] of hits) {
      if (now - rec.start > windowMs) hits.delete(key);
    }
  }, 60 * 1000);
  if (timer.unref) timer.unref();

  return (req, res, next) => {
    const fwd = req.headers['x-forwarded-for'];
    const key = fwd ? String(fwd).split(',')[0].trim() : (req.socket.remoteAddress || 'unknown');
    const now = Date.now();

    let rec = hits.get(key);
    if (!rec || now - rec.start > windowMs) {
      rec = { start: now, count: 0 };
      hits.set(key, rec);
    }
    rec.count += 1;

    if (rec.count > max) {
      console.warn(`🛡 Rate limit exceeded: ${key} (${rec.count} за ${Math.round(windowMs / 60000)} мин)`);
      res.set('Retry-After', String(Math.ceil(windowMs / 1000)));
      return res.status(429).json({ error: 'Слишком много попыток. Попробуйте позже.' });
    }

    next();
  };
}

module.exports = { rateLimit };