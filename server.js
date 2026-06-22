const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { WebSocketServer } = require('ws');
const http = require('http');
const TelegramBot = require('node-telegram-bot-api');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

const clients = new Set();

wss.on('connection', (ws) => {
  clients.add(ws);
  console.log('WebSocket client connected');

  ws.on('close', () => {
    clients.delete(ws);
    console.log('WebSocket client disconnected');
  });
});

function broadcast(data) {
  const message = JSON.stringify(data);
  clients.forEach(client => {
    if (client.readyState === 1) {
      client.send(message);
    }
  });
}

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, async (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

const requireRole = (...roles) => {
  return async (req, res, next) => {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { role: true }
    });

    if (!user || !roles.includes(user.role.name)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    req.userRole = user.role.name;
    next();
  };
};

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    const user = await prisma.user.findUnique({
      where: { username },
      include: { role: true }
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
        message: `User ${username} logged in`
      }
    });

    res.json({ token, user: { id: user.id, username: user.username, role: user.role.name } });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/auth/logout', authenticateToken, async (req, res) => {
  try {
    await prisma.event.create({
      data: {
        eventType: 'INFO',
        message: `User ${req.user.username} logged out`
      }
    });
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { role: true }
    });
    res.json({ id: user.id, username: user.username, role: user.role.name });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/users', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      include: { role: true }
    });
    res.json(users.map(u => ({
      id: u.id,
      username: u.username,
      role: u.role.name,
      telegramId: u.telegramId?.toString(),
      createdAt: u.createdAt
    })));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  try {
    const { username, password, role, telegramId } = req.body;

    const roleRecord = await prisma.role.findUnique({ where: { name: role } });
    if (!roleRecord) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    // Безопасная обработка telegramId
    let telegramIdValue = null;
    if (telegramId && telegramId.toString().trim() !== '') {
      const parsed = parseInt(telegramId.toString().trim());
      if (!isNaN(parsed)) {
        telegramIdValue = BigInt(parsed);
      }
    }

    const user = await prisma.user.create({
      data: {
        username,
        passwordHash,
        roleId: roleRecord.id,
        telegramId: telegramIdValue
      },
      include: { role: true }
    });

    await prisma.event.create({
      data: {
        eventType: 'INFO',
        message: `User ${username} created by ${req.user.username}`
      }
    });

    res.json({ id: user.id, username: user.username, role: user.role.name });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/users/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  try {
    const { username, password, role, telegramId } = req.body;
    const userId = parseInt(req.params.id);

    const updateData = {};
    if (username) updateData.username = username;
    if (password) updateData.passwordHash = await bcrypt.hash(password, 10);
    if (telegramId !== undefined) updateData.telegramId = telegramId ? BigInt(telegramId) : null;

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
      include: { role: true }
    });

    res.json({ id: user.id, username: user.username, role: user.role.name });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/users/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    await prisma.user.delete({ where: { id: userId } });
    res.json({ message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/telemetry/latest', authenticateToken, async (req, res) => {
  try {
    // Запрещаем кэширование
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');

    const telemetry = await prisma.telemetry.findMany({
      orderBy: { timestamp: 'desc' },
      take: 100
    });

    console.log(`📊 Telemetry query returned ${telemetry.length} records`);

    const latest = {};
    telemetry.forEach(t => {
      if (!latest[t.parameter]) {
        latest[t.parameter] = { value: t.value, timestamp: t.timestamp };
      }
    });

    console.log(`📊 Latest parameters:`, Object.keys(latest));
    console.log(`📊 Room temp:`, latest['room_temp']);
    console.log(`📊 Outdoor temp:`, latest['outdoor_temp']);
    console.log(`📊 Boiler temp:`, latest['boiler_temp']);

    res.json(latest);
  } catch (error) {
    console.error(`❌ Error in /api/telemetry/latest:`, error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/telemetry/history', authenticateToken, async (req, res) => {
  try {
    const { parameter, hours = 24 } = req.query;
    const since = new Date(Date.now() - hours * 60 * 60 * 1000);

    const where = { timestamp: { gte: since } };
    if (parameter) where.parameter = parameter;

    const telemetry = await prisma.telemetry.findMany({
      where,
      orderBy: { timestamp: 'asc' }
    });

    res.json(telemetry);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/settings', authenticateToken, async (req, res) => {
  try {
        // Запрещаем кэширование
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    const parameters = await prisma.parameter.findMany();
    res.json(parameters);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/settings/:key', authenticateToken, async (req, res) => {
  try {
    const { key } = req.params;
    const { value } = req.body;

    const updated = await prisma.parameter.update({
      where: { key },
      data: { value, updatedAt: new Date() }
    });

    res.json(updated);
  } catch (error) {
    console.error('Error updating setting:', error);
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/settings', authenticateToken, requireRole('ADMIN', 'OPERATOR'), async (req, res) => {
  try {
    const { parameters } = req.body;

    for (const param of parameters) {
      await prisma.parameter.upsert({
        where: { key: param.key },
        update: { value: param.value },
        create: {
          key: param.key,
          value: param.value,
          description: param.description || ''
        }
      });
    }

    await prisma.event.create({
      data: {
        eventType: 'INFO',
        message: `Settings updated by ${req.user.username}`
      }
    });

    broadcast({ type: 'settings_updated' });
    res.json({ message: 'Settings updated' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/events', authenticateToken, async (req, res) => {
  try {
    const { limit = 100 } = req.query;
    const events = await prisma.event.findMany({
      orderBy: { createdAt: 'desc' },
      take: parseInt(limit)
    });
    res.json(events);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/commands', authenticateToken, requireRole('ADMIN', 'OPERATOR'), async (req, res) => {
  try {
    const { command, payload } = req.body;

    const device = await prisma.device.findFirst();
    if (!device) {
      return res.status(404).json({ error: 'No device configured' });
    }

    const cmd = await prisma.command.create({
      data: {
        deviceId: device.id,
        command,
        payload: payload || {}
      }
    });

    await prisma.event.create({
      data: {
        deviceId: device.id,
        eventType: 'INFO',
        message: `Command ${command} queued by ${req.user.username}`
      }
    });

    broadcast({ type: 'command_queued', command: cmd });
    res.json(cmd);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/commands/pending', async (req, res) => {
  try {
    const commands = await prisma.command.findMany({
      where: { status: 'pending' },
      orderBy: { createdAt: 'asc' }
    });

    res.json(commands);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
// Статус устройства
app.get('/api/device/status', authenticateToken, async (req, res) => {
  try {
    const device = await prisma.device.findFirst({
      orderBy: { createdAt: 'desc' }
    });
    
    if (!device) {
      return res.json({
        name: 'Не настроено',
        online: false,
        lastSeen: null
      });
    }
    
    res.json({
      name: device.name,
      online: device.online,
      lastSeen: device.lastSeen
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
app.post('/api/device/telemetry', async (req, res) => {
  try {
    const { serialNumber, data } = req.body;

    let device = await prisma.device.findUnique({
      where: { serialNumber }
    });

    if (!device) {
      device = await prisma.device.create({
        data: {
          name: `ESP32-${serialNumber}`,
          serialNumber,
          online: true,
          lastSeen: new Date()
        }
      });
    } else {
      await prisma.device.update({
        where: { id: device.id },
        data: { online: true, lastSeen: new Date() }
      });
    }

    for (const [parameter, value] of Object.entries(data)) {
      await prisma.telemetry.create({
        data: {
          deviceId: device.id,
          parameter,
          value: String(value)
        }
      });
    }

    broadcast({ type: 'telemetry_updated', data });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/device/command/:id/executed', async (req, res) => {
  try {
    const commandId = parseInt(req.params.id);
    await prisma.command.update({
      where: { id: commandId },
      data: { status: 'executed', executedAt: new Date() }
    });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN, { polling: true });

bot.onText(/\/start/, async (msg) => {
  const chatId = msg.chat.id;
  await bot.sendMessage(chatId, 'Добро пожаловать в систему управления отоплением!\n\nИспользуйте /help для списка команд.');
});

bot.onText(/\/help/, async (msg) => {
  const chatId = msg.chat.id;
  const helpText = `
Доступные команды:

/start - Начать работу
/status - Статус системы
/events - Последние события
/settings - Настройки системы
/help - Список команд

Управление (только для ADMIN и OPERATOR):
/boiler_on - Включить котел
/boiler_off - Выключить котел
/floor_pump_on - Включить насос теплого пола
/floor_pump_off - Выключить насос теплого пола
/radiator_pump_on - Включить насос радиаторов
/radiator_pump_off - Выключить насос радиаторов
  `;
  await bot.sendMessage(chatId, helpText);
});

bot.onText(/\/status/, async (msg) => {
  const chatId = msg.chat.id;
  const user = await prisma.user.findUnique({
    where: { telegramId: BigInt(msg.from.id) },
    include: { role: true }
  });


  console.log('Telegram message from user ID:', msg.from.id);
  if (!user) {
    await bot.sendMessage(chatId, 'Ваш Telegram не привязан к системе. Обратитесь к администратору.');
    return;
  }

  const device = await prisma.device.findFirst();
  const telemetry = await prisma.telemetry.findMany({
    orderBy: { timestamp: 'desc' },
    take: 10
  });

  const latest = {};
  telemetry.forEach(t => {
    if (!latest[t.parameter]) {
      latest[t.parameter] = t.value;
    }
  });

  const statusText = `
📊 Статус системы

Устройство: ${device?.name || 'Не настроено'}
Статус: ${device?.online ? '🟢 ONLINE' : '🔴 OFFLINE'}
Последняя связь: ${device?.lastSeen?.toLocaleString('ru-RU') || 'Нет данных'}

Телеметрия:
- Температура помещения: ${latest.room_temp || 'Нет данных'}°C
- Температура улицы: ${latest.outdoor_temp || 'Нет данных'}°C
- Режим: ${latest.mode || 'Нет данных'}
  `;

  await bot.sendMessage(chatId, statusText);
});

bot.onText(/\/events/, async (msg) => {
  const chatId = msg.chat.id;
  const user = await prisma.user.findUnique({
    where: { telegramId: BigInt(msg.from.id) }
  });

  if (!user) {
    await bot.sendMessage(chatId, 'Ваш Telegram не привязан к системе.');
    return;
  }

  const events = await prisma.event.findMany({
    orderBy: { createdAt: 'desc' },
    take: 10
  });

  const eventsText = events.map(e => 
    `${e.createdAt.toLocaleString('ru-RU')} - ${e.eventType}: ${e.message}`
  ).join('\n');

  await bot.sendMessage(chatId, `📋 Последние события:\n\n${eventsText || 'Нет событий'}`);
});

bot.onText(/\/settings/, async (msg) => {
  const chatId = msg.chat.id;
  const user = await prisma.user.findUnique({
    where: { telegramId: BigInt(msg.from.id) }
  });

  if (!user) {
    await bot.sendMessage(chatId, 'Ваш Telegram не привязан к системе.');
    return;
  }

  const parameters = await prisma.parameter.findMany();
  const settingsText = parameters.map(p => 
    `${p.key}: ${p.value}${p.description ? ` (${p.description})` : ''}`
  ).join('\n');

  await bot.sendMessage(chatId, `⚙️ Настройки:\n\n${settingsText || 'Нет настроек'}`);
});

const commandHandlers = {
  '/boiler_on': 'boiler_on',
  '/boiler_off': 'boiler_off',
  '/floor_pump_on': 'floor_pump_on',
  '/floor_pump_off': 'floor_pump_off',
  '/radiator_pump_on': 'radiator_pump_on',
  '/radiator_pump_off': 'radiator_pump_off'
};

Object.keys(commandHandlers).forEach(cmd => {
  bot.onText(new RegExp(`\\${cmd}`), async (msg) => {
    const chatId = msg.chat.id;
    const user = await prisma.user.findUnique({
      where: { telegramId: BigInt(msg.from.id) },
      include: { role: true }
    });

    if (!user || !['ADMIN', 'OPERATOR'].includes(user.role.name)) {
      await bot.sendMessage(chatId, 'Недостаточно прав для выполнения этой команды.');
      return;
    }

    const device = await prisma.device.findFirst();
    if (!device) {
      await bot.sendMessage(chatId, 'Устройство не настроено.');
      return;
    }

    await prisma.command.create({
      data: {
        deviceId: device.id,
        command: commandHandlers[cmd],
        payload: {}
      }
    });

    await prisma.event.create({
      data: {
        deviceId: device.id,
        eventType: 'INFO',
        message: `Command ${commandHandlers[cmd]} from Telegram by ${user.username}`
      }
    });

    await bot.sendMessage(chatId, `✅ Команда ${commandHandlers[cmd]} отправлена в очередь.`);
  });
});

async function sendNotification(type, message) {
  const users = await prisma.user.findMany({
    where: { telegramId: { not: null } }
  });

  const emoji = {
    'INFO': 'ℹ️',
    'WARNING': '⚠️',
    'ERROR': '❌',
    'ALARM': '🚨'
  };

  for (const user of users) {
    await bot.sendMessage(
      user.telegramId.toString(),
      `${emoji[type]} ${message}\n\n${new Date().toLocaleString('ru-RU')}`
    );
  }

  await prisma.event.create({
    data: {
      eventType: type,
      message
    }
  });
}

global.sendNotification = sendNotification;

async function initializeDatabase() {
  try {
    const roles = ['ADMIN', 'OPERATOR', 'VIEWER'];
    for (const roleName of roles) {
      await prisma.role.upsert({
        where: { name: roleName },
        update: {},
        create: {
          name: roleName,
          description: `${roleName} role`
        }
      });
    }

    const adminRole = await prisma.role.findUnique({ where: { name: 'ADMIN' } });
    const existingAdmin = await prisma.user.findUnique({ where: { username: 'admin' } });
    
    if (!existingAdmin && adminRole) {
      const passwordHash = await bcrypt.hash('admin123', 10);
      await prisma.user.create({
        data: {
          username: 'admin',
          passwordHash,
          roleId: adminRole.id
        }
      });
      console.log('Default admin user created (username: admin, password: admin123)');
    }

    const defaultParams = [
      { key: 'night_start', value: '22:00', description: 'Ночной режим начало' },
      { key: 'night_end', value: '06:00', description: 'Ночной режим конец' },
      { key: 'room_target_temp', value: '22', description: 'Целевая температура помещения' },
      { key: 'floor_pump_on_temp', value: '25', description: 'Температура включения насоса теплого пола' },
      { key: 'floor_pump_off_temp', value: '20', description: 'Температура выключения насоса теплого пола' },
      { key: 'boiler_max_temp', value: '60', description: 'Максимальная температура котла' }
    ];

    for (const param of defaultParams) {
      await prisma.parameter.upsert({
        where: { key: param.key },
        update: {},
        create: param
      });
    }

    const existingDevice = await prisma.device.findFirst();
    if (!existingDevice) {
      await prisma.device.create({
        data: {
          name: 'ESP32-Heating-Controller',
          serialNumber: 'ESP32-001',
          online: false
        }
      });
    }

    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Database initialization error:', error);
  }
}

const PORT = process.env.PORT || 3000;

server.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await initializeDatabase();
});