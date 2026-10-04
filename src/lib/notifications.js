// src/lib/notifications.js
// Рассылка уведомлений по Telegram всем пользователям с привязанным ID
// + запись события в журнал.

function createNotifier({ prisma, bot }) {
  const EMOJI = {
    INFO: 'ℹ️',
    WARNING: '⚠️',
    ERROR: '❌',
    ALARM: '🚨',
  };

  return async function sendNotification(type, message) {
    const users = await prisma.user.findMany({
      where: { telegramId: { not: null } },
    });

    if (bot) {
      for (const user of users) {
        try {
          await bot.sendMessage(
            user.telegramId.toString(),
            `${EMOJI[type] || '📌'} ${message}\n\n${new Date().toLocaleString('ru-RU')}`
          );
        } catch (err) {
          // Пользователь мог заблокировать бота — не роняем всю рассылку
          console.error(`Telegram send failed for user ${user.id}:`, err.message);
        }
      }
    }

    await prisma.event.create({
      data: { eventType: type, message },
    });
  };
}

module.exports = { createNotifier };