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
// Логирование всех запросов
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Body:', JSON.stringify(req.body).substring(0, 200));
  }
  next();
});

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
  return (req, res, next) => {
    // Роль уже есть в req.user из JWT-токена
    if (!req.user || !req.user.role) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    
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

    // Сначала попробовать прочитать из кэша DeviceCache
    const cache = await prisma.deviceCache.findFirst({
      orderBy: { lastSync: 'desc' }
    });
    
    if (cache && cache.telemetry) {
      const latest = {};
      for (const [parameter, value] of Object.entries(cache.telemetry)) {
        latest[parameter] = { value, timestamp: cache.lastSync };
      }
      
      // Добавить фазы
      if (cache.phases) {
        latest.phases = { value: cache.phases, timestamp: cache.lastSync };
      }
      
      console.log(`📊 Telemetry from cache:`, Object.keys(latest));
      return res.json(latest);
    }
    
    // Если кэша нет, читать из старой таблицы telemetry
    const telemetry = await prisma.telemetry.findMany({
      orderBy: { timestamp: 'desc' },
      take: 100
    });

    const latestFromDb = {};
    telemetry.forEach(t => {
      if (!latestFromDb[t.parameter]) {
        latestFromDb[t.parameter] = { value: t.value, timestamp: t.timestamp };
      }
    });

    console.log(`📊 Telemetry from DB:`, Object.keys(latestFromDb));
    res.json(latestFromDb);
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
    
    // Сначала пробуем прочитать из кэша DeviceCache (данные от ESP32)
    const cache = await prisma.deviceCache.findFirst({
      orderBy: { lastSync: 'desc' }
    });
    
    if (cache && cache.settings && Object.keys(cache.settings).length > 0) {
      // Преобразовать JSON в массив параметров (как ожидает фронтенд)
      const settings = Object.entries(cache.settings).map(([key, value]) => ({
        key,
        value: String(value),
        updatedAt: cache.lastSync
      }));
      
      return res.json(settings);
    }
    
    // FALLBACK: Если кэш пустой — вернуть из старой таблицы Parameter
    console.log('⚠️ Device cache is empty, falling back to Parameter table');
    const parameters = await prisma.parameter.findMany();
    res.json(parameters);
  } catch (error) {
    console.error('Error in GET /api/settings:', error);
    res.status(500).json({ error: error.message });
  }
});

app.put('/api/settings/:key', authenticateToken, requireRole('ADMIN', 'OPERATOR'), async (req, res) => {
  try {
    const { key } = req.params;
    const { value } = req.body;
    
    // Найти устройство
    const device = await prisma.device.findFirst({
      orderBy: { createdAt: 'desc' }
    });
    
    if (!device) {
      return res.status(404).json({ error: 'No device configured' });
    }

    // Создать команду для ESP32
    const command = await prisma.command.create({
      data: {
        deviceId: device.id,
        command: 'SET_SETTING',
        payload: { key, value: parseFloat(value) || value },
        status: 'pending'
      }
    });
    
    // Оптимистично обновить кэш (чтобы UI сразу показал новое значение)
    const cache = await prisma.deviceCache.findFirst({
      orderBy: { lastSync: 'desc' }
    });
    
    if (cache && cache.settings) {
      const settings = { ...cache.settings };
      settings[key] = parseFloat(value) || value;
      
      await prisma.deviceCache.update({
        where: { id: cache.id },
        data: { settings }
      });
    }
    
    // Также обновить старую таблицу Parameter (для обратной совместимости)
    try {
      await prisma.parameter.upsert({
        where: { key },
        update: { value: String(value) },
        create: { key, value: String(value) }
      });
    } catch (e) {
      // Игнорируем ошибку, если параметра нет в старой таблице
    }

    await prisma.event.create({
      data: {
        eventType: 'INFO',
        message: `Setting ${key} change requested by ${req.user.username}`
      }
    });
    
    // Отправить обновление через WebSocket
    broadcast({ type: 'settings_updated' });
    
    res.json({ 
      success: true, 
      commandId: command.id,
      message: 'Command queued for ESP32'
    });
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

    res.json(commands.map(cmd => ({
      id: cmd.id,
      type: cmd.command,
      payload: cmd.payload,
      createdAt: cmd.createdAt.getTime()
    })));
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
        lastSeen: null,
        deviceStatus: {},
        uptime: null,
        firmware: null
      });
    }
    
    // Получить кэш для дополнительной информации
    const cache = await prisma.deviceCache.findFirst({
      where: { deviceId: device.serialNumber || 'ESP32-001' }
    });
    
    // Проверить, онлайн ли устройство (последняя синхронизация менее 2 минут назад)
    const isOnline = device.lastSeen && (Date.now() - device.lastSeen.getTime()) < 120000;
    
    res.json({
      name: device.name,
      online: isOnline,
      lastSeen: device.lastSeen,
      deviceStatus: cache?.deviceStatus || {},
      uptime: cache?.uptime,
      firmware: cache?.firmware || device.firmwareVersion,
      lastSync: cache?.lastSync
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

// ============================================
// ESP32 SYNC API - Приём данных от ESP32
// ============================================

// ESP32 отправляет все данные (настройки, телеметрию, статусы)
app.post('/api/device/sync', async (req, res) => {
  try {
    const { deviceId, timestamp, uptime, firmware, settings, telemetry, device_status, events, alarms } = req.body;
    
    console.log(`📡 Sync from ${deviceId || 'unknown'} at ${new Date().toISOString()}`);
    
    // Обновить кэш последних данных
    await prisma.deviceCache.upsert({
      where: { deviceId: deviceId || 'ESP32-001' },
      update: {
        settings: settings || undefined,
        telemetry: telemetry || undefined,
        deviceStatus: device_status || undefined,
        phases: req.body.phases || undefined,
        lastSync: new Date(),
        uptime: uptime,
        firmware: firmware
      },
      create: {
        deviceId: deviceId || 'ESP32-001',
        settings: settings || {},
        telemetry: telemetry || {},
        deviceStatus: device_status || {},
        phases: req.body.phases || {},
        lastSync: new Date(),
        uptime: uptime,
        firmware: firmware
      }
    });
    
    // Также обновить статус устройства в таблице Device
    const device = await prisma.device.findFirst({
      where: { serialNumber: deviceId }
    });
    
    if (device) {
      await prisma.device.update({
        where: { id: device.id },
        data: { 
          online: true, 
          lastSeen: new Date(),
          firmwareVersion: firmware
        }
      });
    }
    
    // Сохранить события в историю
    if (events && Array.isArray(events) && events.length > 0) {
      for (const event of events) {
        // Проверить, не было ли уже такое событие (по eventId)
        const existing = await prisma.deviceEvent.findFirst({
          where: {
            deviceId: deviceId || 'ESP32-001',
            eventId: event.id
          }
        });
        
        if (!existing) {
          await prisma.deviceEvent.create({
            data: {
              deviceId: deviceId || 'ESP32-001',
              eventId: event.id,
              timestamp: new Date(event.timestamp * 1000),
              type: event.type,
              message: event.message
            }
          });
          
          // Также сохранить в основную таблицу events (для UI)
          await prisma.event.create({
            data: {
              deviceId: device?.id,
              eventType: event.type,
              message: event.message
            }
          });
        }
      }
    }
    
    // Сохранить телеметрию в историю (для графиков)
    if (telemetry && device) {
      for (const [parameter, value] of Object.entries(telemetry)) {
        await prisma.telemetry.create({
          data: {
            deviceId: device.id,
            parameter,
            value: String(value)
          }
        });
      }
    }
    
    // Забрать команды из очереди для ESP32
    const commands = await prisma.command.findMany({
      where: { 
        status: 'pending',
        deviceId: device?.id || 1
      },
      orderBy: { createdAt: 'asc' }
    });
    
    // Пометить команды как отправленные
    if (commands.length > 0) {
      await prisma.command.updateMany({
        where: { id: { in: commands.map(c => c.id) } },
        data: { status: 'sent' }
      });
    }
    
    // Отправить обновление через WebSocket клиентам
    broadcast({ 
      type: 'device_sync', 
      deviceId,
      telemetry,
      device_status,
      timestamp: Date.now()
    });
    
    res.json({
      success: true,
      serverTime: Math.floor(Date.now() / 1000),
      commands: commands.map(cmd => ({
        id: cmd.id,
        type: cmd.command,
        payload: cmd.payload,
        createdAt: cmd.createdAt.getTime()
      }))
    });
    
  } catch (error) {
    console.error('❌ Error in /api/device/sync:', error);
    res.status(500).json({ error: error.message });
  }
});

// ESP32 подтверждает выполнение команды
app.post('/api/device/command/:id/executed', async (req, res) => {
  try {
    const commandId = parseInt(req.params.id);
    const { success, message } = req.body;
    
    await prisma.command.update({
      where: { id: commandId },
      data: { 
        status: success ? 'executed' : 'failed',
        executedAt: new Date()
      }
    });
    
    if (success) {
      await prisma.event.create({
        data: {
          eventType: 'INFO',
          message: `Command ${commandId} executed successfully: ${message || ''}`
        }
      });
    } else {
      await prisma.event.create({
        data: {
          eventType: 'ERROR',
          message: `Command ${commandId} failed: ${message || 'Unknown error'}`
        }
      });
    }
    
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

    // Инициализация настроек по умолчанию (если их нет)
    const defaultParams = [
      // Помещение
      { key: 'room_temp_target', value: '22.0', description: 'Целевая температура помещения' },
      { key: 'room_temp_threshold_on', value: '21.5', description: 'Порог включения отопления' },
      { key: 'room_temp_threshold_off', value: '22.5', description: 'Порог выключения отопления' },
      
      // Котёл
      { key: 'boiler_temp_target', value: '60.0', description: 'Целевая температура котла' },
      { key: 'boiler_temp_threshold_on', value: '55.0', description: 'Порог включения котла' },
      { key: 'boiler_temp_threshold_off', value: '65.0', description: 'Порог выключения котла' },
      
      // Тёплый пол
      { key: 'floor_temp_target', value: '25.0', description: 'Целевая температура тёплого пола' },
      { key: 'floor_temp_threshold_on', value: '24.0', description: 'Порог включения насоса ТП' },
      { key: 'floor_temp_threshold_off', value: '26.0', description: 'Порог выключения насоса ТП' },
      
      // Теплоаккумулятор
      { key: 'accumulator_temp_target', value: '65.0', description: 'Целевая температура ТА' },
      { key: 'accumulator_temp_threshold_on', value: '60.0', description: 'Порог включения ЭК' },
      { key: 'accumulator_temp_threshold_off', value: '70.0', description: 'Порог выключения ЭК' },
      
      // Режимы
      { key: 'night_start', value: '22:00', description: 'Начало ночного режима' },
      { key: 'night_end', value: '06:00', description: 'Конец ночного режима' },
      { key: 'manual_timeout', value: '30', description: 'Таймаут ручного управления (сек)' }
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

    console.log('✅ Default parameters initialized');
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