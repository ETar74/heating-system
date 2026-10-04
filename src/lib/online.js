// src/lib/online.js
// Единственный источник истины для «онлайн» статуса ESP32:
// последняя успешная синхронизация менее 2 минут назад.

const ONLINE_WINDOW_MS = 2 * 60 * 1000;

function createOnlineChecker(prisma) {
  const isDeviceOnline = async () => {
    const cache = await prisma.deviceCache.findFirst({
      orderBy: { lastSync: 'desc' },
    });
    if (!cache || !cache.lastSync) return false;
    return cache.lastSync.getTime() > Date.now() - ONLINE_WINDOW_MS;
  };

  // Middleware: блокировка изменений если ESP32 офлайн (HTTP 423 Locked)
  const requireDeviceOnline = async (req, res, next) => {
    let online = false;
    try {
      online = await isDeviceOnline();
    } catch (err) {
      console.error('isDeviceOnline error:', err.message);
    }

    if (!online) {
      return res.status(423).json({
        error: 'Device offline',
        message: 'Изменение настроек заблокировано: устройство ESP32 недоступно. Дождитесь восстановления связи.',
      });
    }
    next();
  };

  return { isDeviceOnline, requireDeviceOnline };
}

module.exports = { createOnlineChecker };