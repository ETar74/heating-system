require('dotenv').config();

const express = require('express');
const cors = require('cors');
const http = require('http');
const { WebSocketServer } = require('ws');
const { PrismaClient } = require('@prisma/client');
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

const prisma = new PrismaClient();
const { isDeviceOnline, requireDeviceOnline } = createOnlineChecker(prisma);

// ================= WebSocket Настройка =================
const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// Разделяем клиентов на пользователей и устройства
const userClients = new Set();
const deviceClients = new Set();

// Функция отправки сообщения всем пользователям (Frontend)
function broadcastToUsers(event, data) {
  const message = JSON.stringify({ event, data });
  userClients.forEach((client) => {
    if (client.readyState === 1) client.send(message);
  });
}

// Функция отправки сообщения всем устройствам (ESP32)
function broadcastToDevice(event, data) {
  const message = JSON.stringify({ event, data });
  deviceClients.forEach((client) => {
    if (client.readyState === 1) client.send(message);
  });
}

wss.on('connection', (ws, req) => {
  let isValid = false;
  let clientType = 'unknown';

  try {
    const url = new URL(req.url, 'http://localhost');
    const token = url.searchParams.get('token');
    
    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      isValid = true;
      // Определяем тип клиента по роли в токене
      clientType = decoded.role === 'DEVICE' ? 'device' : 'user';
      ws.user = decoded; // Сохраняем данные пользователя/устройства в объекте ws
    }
  } catch (err) {
    isValid = false;
  }

  if (!isValid) {
    ws.close(4001, 'unauthorized');
    return;
  }

  if (clientType === 'device') {
    deviceClients.add(ws);
    console.log(`[WS] 📡 Device connected: ${ws.user.deviceId || 'unknown'}`);
  } else {
    userClients.add(ws);
    console.log(`[WS] 👤 User connected: ${ws.user.username || 'unknown'}`);
  }

  ws.on('close', () => {
    userClients.delete(ws);
    deviceClients.delete(ws);
    console.log(`[WS] Client disconnected`);
  });

  // Обработка сообщений от ESP32 (например, подтверждение выполнения команды)
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());
      if (data.event === 'device:command_ack') {
        console.log(`[WS] ✅ Device acknowledged command: ${data.commandId}`);
        // Можно обновить статус команды в БД здесь, если нужно
      }
    } catch (e) {
      console.error('[WS] Invalid message format:', e.message);
    }
  });
});

// ================= Express Настройка =================
const CORS_ORIGINS = (process.env.CORS_ORIGINS || 'http://localhost:5173').split(',').map(s => s.trim()).filter(Boolean);
app.use(cors({ origin: CORS_ORIGINS }));

// 🛑 ВОЗВРАЩАЕМ СТАНДАРТНЫЙ, 100% РАБОЧИЙ ПАРСЕР JSON
// Кастомный парсер удален, так как он ломал синхронизацию. 
// Лимит 500kb гарантирует, что большие пакеты от ESP32 пройдут без ошибок.
app.use(express.json({ limit: '500kb' }));

// Логирование запросов
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// 🛑 Делаем функции WebSocket доступными во всех роутах через объект req
app.use((req, res, next) => {
  req.broadcastToUsers = broadcastToUsers;
  req.broadcastToDevice = broadcastToDevice;
  next();
});

app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'ok', db: true, deviceOnline: await isDeviceOnline(), uptime: process.uptime() });
  } catch (error) {
    res.status(503).json({ status: 'error', db: false });
  }
});

const bot = initTelegramBot({ prisma });

// Передаём зависимости в роуты
app.use('/api/auth', createAuthRoutes({ prisma }));
app.use('/api/users', createUsersRoutes({ prisma, bot }));
app.use('/api/telemetry', createTelemetryRoutes({ prisma }));
app.use('/api/settings', createSettingsRoutes({ prisma, isDeviceOnline, requireDeviceOnline }));
app.use('/api/events', createEventsRoutes({ prisma }));
app.use('/api/commands', createCommandsRoutes({ prisma, authenticateDevice }));
app.use('/api/device', createDeviceRoutes({ prisma, authenticateDevice, isDeviceOnline }));

// ================= OTA Загрузка =================
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const safeName = path.basename(file.originalname || 'firmware.bin').replace(/[\\/:*?"<>|]/g, '_');
    cb(null, uniqueSuffix + '-' + safeName);
  },
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });
app.use('/api/ota', createOtaRoutes({ prisma, uploadDir, upload, authenticateDevice }));

// ================= Алерты и очистка =================
// const sendNotification = createNotifier({ prisma, bot });
// const alarmEngine = new AlarmEngine({ prisma, notify: sendNotification });
// setInterval(() => alarmEngine.check().catch(err => console.error('Alarm check error:', err.message)), 60 * 1000);

// const RETENTION_DAYS = parseInt(process.env.TELEMETRY_RETENTION_DAYS, 10) || 30;
// setInterval(async () => {
//   try {
//     const since = new Date(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000);
//     const result = await prisma.telemetry.deleteMany({ where: { timestamp: { lt: since } } });
//     if (result.count > 0) console.log(`🧹 Очистка телеметрии: удалено ${result.count} записей`);
//   } catch (err) { console.error('Telemetry cleanup error:', err.message); }
// }, 24 * 60 * 60 * 1000);

// app.use((err, req, res, next) => {
//   if (err instanceof multer.MulterError) {
//     if (err.code === 'FILE_TOO_LARGE') return res.status(413).json({ error: 'Файл слишком большой (макс 5 МБ)' });
//     return res.status(400).json({ error: `Ошибка загрузки: ${err.message}` });
//   }
//   console.error('Unhandled error:', err);
//   if (!res.headersSent) res.status(500).json({ error: err.message });
// });

// const PORT = process.env.PORT || 3000;
// // '0.0.0.0' означает "слушать запросы отовсюду, а не только с этого компьютера"
// server.listen(PORT, '0.0.0.0', async () => {
//   console.log(`🚀 Server + WebSocket running on port ${PORT} (доступен в локальной сети)`);
//   await initializeDatabase(prisma);
// });
//app.use('/api/ota', createOtaRoutes({ prisma, uploadDir, upload, authenticateDevice }));
// ================= Алерты и очистка =================
const sendNotification = createNotifier({ prisma, bot });
const alarmEngine = new AlarmEngine({ prisma, notify: sendNotification });
setInterval(() => alarmEngine.check().catch(err => console.error('Alarm check error:', err.message)), 60 * 1000);

const RETENTION_DAYS = parseInt(process.env.TELEMETRY_RETENTION_DAYS, 10) || 30;
setInterval(async () => {
  try {
    const since = new Date(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000);
    const result = await prisma.telemetry.deleteMany({ where: { timestamp: { lt: since } } });
    if (result.count > 0) console.log(`🧹 Очистка телеметрии: удалено ${result.count} записей`);
  } catch (err) { console.error('Telemetry cleanup error:', err.message); }
}, 24 * 60 * 60 * 1000);

app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'FILE_TOO_LARGE') return res.status(413).json({ error: 'Файл слишком большой (макс 5 МБ)' });
    return res.status(400).json({ error: `Ошибка загрузки: ${err.message}` });
  }
  console.error('Unhandled error:', err);
  if (!res.headersSent) res.status(500).json({ error: err.message });
});

const PORT = process.env.PORT || 3000;
// '0.0.0.0' означает "слушать запросы отовсюду, а не только с этого компьютера"
server.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Server + WebSocket running on port ${PORT} (доступен в локальной сети)`);
  await initializeDatabase(prisma);
});