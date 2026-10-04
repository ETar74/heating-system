require('dotenv').config();

const express = require('express');
const cors = require('cors');
const http = require('http');
const { PrismaClient } = require('@prisma/client');
const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const { authenticateDevice } = require('./src/middleware/deviceAuth');
const { createOnlineChecker } = require('./src/lib/online');
const { AlarmEngine } = require('./src/lib/alarms');
const { createNotifier } = require('./src/lib/notifications');
const { initializeDatabase } = require('./src/lib/seed');
const { initTelegramBot } = require('./src/bot');

const createAuthRoutes = require('./src/routes/auth');
const createUsersRoutes = require('./src/routes/users');
const createTelemetryRoutes = require('./src/routes/telemetry');
const createSettingsRoutes = require('./src/routes/settings');
const createEventsRoutes = require('./src/routes/events');
const createCommandsRoutes = require('./src/routes/commands');
const createDeviceRoutes = require('./src/routes/device');
const createOtaRoutes = require('./src/routes/ota');

// ================= Prisma =================
const prisma = new PrismaClient();
const { isDeviceOnline, requireDeviceOnline } = createOnlineChecker(prisma);

// ================= Загрузка файлов (OTA) =================
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    // Санитизация исходного имени (защита от path traversal)
    const safeName = path.basename(file.originalname || 'firmware.bin').replace(/[\\/:*?"<>|]/g, '_');
    cb(null, uniqueSuffix + '-' + safeName);
  },
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } }); // до 5 МБ

// ================= Express =================
const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });
const clients = new Set();

function broadcast(data) {
  const message = JSON.stringify(data);
  clients.forEach((client) => {
    if (client.readyState === 1) {
      client.send(message);
    }
  });
}

// WebSocket: только с валидным JWT (?token=<JWT>)
wss.on('connection', (ws, req) => {
  let valid = false;
  try {
    const url = new URL(req.url, 'http://localhost');
    const token = url.searchParams.get('token');
    if (token) {
      jwt.verify(token, process.env.JWT_SECRET);
      valid = true;
    }
  } catch (err) {
    valid = false;
  }

  if (!valid) {
    ws.close(4001, 'unauthorized');
    return;
  }

  clients.add(ws);
  console.log('WebSocket client connected');

  ws.on('close', () => {
    clients.delete(ws);
    console.log('WebSocket client disconnected');
  });
});

// CORS: только разрешённые origins
const CORS_ORIGINS = (process.env.CORS_ORIGINS || 'http://localhost:5173')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
app.use(cors({ origin: CORS_ORIGINS }));
app.use(express.json({ limit: '250kb' }));

// Логирование запросов (без тела — оно часто содержит чувствительные данные)
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Health check (для docker healthcheck и мониторинга)
app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({
      status: 'ok',
      db: true,
      deviceOnline: await isDeviceOnline(),
      uptime: process.uptime(),
    });
  } catch (error) {
    res.status(503).json({ status: 'error', db: false });
  }
});

// ================= Telegram-бот (null, если токен не задан) =================
const bot = initTelegramBot({ prisma });

// ================= Маршруты =================
app.use('/api/auth', createAuthRoutes({ prisma }));
app.use('/api/users', createUsersRoutes({ prisma, bot }));
app.use('/api/telemetry', createTelemetryRoutes({ prisma }));
app.use('/api/settings', createSettingsRoutes({ prisma, broadcast, isDeviceOnline, requireDeviceOnline }));
app.use('/api/events', createEventsRoutes({ prisma }));
app.use('/api/commands', createCommandsRoutes({ prisma, broadcast, authenticateDevice }));
app.use('/api/device', createDeviceRoutes({ prisma, broadcast, authenticateDevice, isDeviceOnline }));
app.use('/api/ota', createOtaRoutes({ prisma, broadcast, uploadDir, upload, authenticateDevice }));

// ================= Алерты и обслуживание =================
const sendNotification = createNotifier({ prisma, bot });

const alarmEngine = new AlarmEngine({ prisma, notify: sendNotification });
setInterval(() => {
  alarmEngine.check().catch((err) => console.error('Alarm check error:', err.message));
}, 60 * 1000);

// Ротация телеметрии: удаляем сырые данные старше N дней
const RETENTION_DAYS = parseInt(process.env.TELEMETRY_RETENTION_DAYS, 10) || 30;
setInterval(async () => {
  try {
    const since = new Date(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000);
    const result = await prisma.telemetry.deleteMany({ where: { timestamp: { lt: since } } });
    if (result.count > 0) {
      console.log(`🧹 Очистка телеметрии: удалено ${result.count} записей старше ${RETENTION_DAYS} дн.`);
    }
  } catch (err) {
    console.error('Telemetry cleanup error:', err.message);
  }
}, 24 * 60 * 60 * 1000);

// ================= Глобальный обработчик ошибок =================
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'FILE_TOO_LARGE') {
      return res.status(413).json({ error: 'Файл слишком большой (максимум 5 МБ)' });
    }
    return res.status(400).json({ error: `Ошибка загрузки: ${err.message}` });
  }
  if (err && err.type === 'entity.too.large') {
    return res.status(413).json({ error: 'Слишком большое тело запроса' });
  }
  console.error('Unhandled error:', err);
  if (!res.headersSent) {
    res.status(500).json({ error: err.message });
  }
});

// ================= Запуск =================
const PORT = process.env.PORT || 3000;
server.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await initializeDatabase(prisma);
});