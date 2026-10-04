// src/bot.js
// Telegram-бот: статус, события, настройки, команды управления, привязка аккаунта.
// Если TELEGRAM_BOT_TOKEN не задан — бот не запускается (возвращает null).

const TelegramBot = require('node-telegram-bot-api');
const { createCode } = require('./lib/bindCodes');

function initTelegramBot({ prisma }) {
  if (!process.env.TELEGRAM_BOT_TOKEN) {
    console.log('ℹ️  Telegram-бот выключен: TELEGRAM_BOT_TOKEN не задан в .env');
    return null;
  }

  const bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN, { polling: true });

  bot.onText(/\/start/, async (msg) => {
    const chatId = msg.chat.id;
    await bot.sendMessage(
      chatId,
      'Добро пожаловать в систему управления отоплением!\n\nИспользуйте /help для списка команд.'
    );
  });

  bot.onText(/\/help/, async (msg) => {
    const chatId = msg.chat.id;
    const helpText = `
Доступные команды:

/start - Начать работу
/status - Статус системы
/events - Последние события
/settings - Настройки системы
/bind - Получить код для привязки Telegram к аккаунту
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

  // Привязка Telegram к аккаунту: код вводит администратор в веб-интерфейсе
  bot.onText(/\/bind/, async (msg) => {
    const chatId = msg.chat.id;
    const code = createCode(BigInt(msg.from.id));
    await bot.sendMessage(
      chatId,
      `🔗 Ваш код привязки: ${code}\n\nДействует 10 минут.\nАдминистратор должен ввести этот код на странице «Пользователи» в веб-интерфейсе.`
    );
  });

  bot.onText(/\/status/, async (msg) => {
    const chatId = msg.chat.id;
    const user = await prisma.user.findUnique({
      where: { telegramId: BigInt(msg.from.id) },
      include: { role: true },
    });

    if (!user) {
      await bot.sendMessage(chatId, 'Ваш Telegram не привязан к системе. Отправьте /bind и введите код у администратора.');
      return;
    }

    const device = await prisma.device.findFirst();
    const telemetry = await prisma.telemetry.findMany({
      orderBy: { timestamp: 'desc' },
      take: 10,
    });

    const latest = {};
    telemetry.forEach((t) => {
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
      where: { telegramId: BigInt(msg.from.id) },
    });

    if (!user) {
      await bot.sendMessage(chatId, 'Ваш Telegram не привязан к системе.');
      return;
    }

    const events = await prisma.event.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    const eventsText = events
      .map((e) => `${e.createdAt.toLocaleString('ru-RU')} - ${e.eventType}: ${e.message}`)
      .join('\n');

    await bot.sendMessage(chatId, `📋 Последние события:\n\n${eventsText || 'Нет событий'}`);
  });

  bot.onText(/\/settings/, async (msg) => {
    const chatId = msg.chat.id;
    const user = await prisma.user.findUnique({
      where: { telegramId: BigInt(msg.from.id) },
    });

    if (!user) {
      await bot.sendMessage(chatId, 'Ваш Telegram не привязан к системе.');
      return;
    }

    const parameters = await prisma.parameter.findMany();
    const settingsText = parameters
      .map((p) => `${p.key}: ${p.value}${p.description ? ` (${p.description})` : ''}`)
      .join('\n');

    await bot.sendMessage(chatId, `⚙️ Настройки:\n\n${settingsText || 'Нет настроек'}`);
  });

  // Команды управления — только ADMIN и OPERATOR
  const commandHandlers = {
    '/boiler_on': 'boiler_on',
    '/boiler_off': 'boiler_off',
    '/floor_pump_on': 'floor_pump_on',
    '/floor_pump_off': 'floor_pump_off',
    '/radiator_pump_on': 'radiator_pump_on',
    '/radiator_pump_off': 'radiator_pump_off',
  };

  Object.keys(commandHandlers).forEach((cmd) => {
    // ^ и (\\s|$): чтобы "/boiler_on_off" не сработало как "/boiler_on"
    bot.onText(new RegExp(`^\\${cmd}(\\s|$)`), async (msg) => {
      const chatId = msg.chat.id;
      const user = await prisma.user.findUnique({
        where: { telegramId: BigInt(msg.from.id) },
        include: { role: true },
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
          payload: {},
        },
      });

      await prisma.event.create({
        data: {
          deviceId: device.id,
          eventType: 'INFO',
          message: `Команда ${commandHandlers[cmd]} отправлена по Telegram (${user.username})`,
        },
      });

      await bot.sendMessage(chatId, `✅ Команда ${commandHandlers[cmd]} отправлена в очередь.`);
    });
  });

  return bot;
}

module.exports = { initTelegramBot };