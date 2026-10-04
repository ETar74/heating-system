// src/lib/bindCodes.js
// Одноразовые коды привязки Telegram к аккаунту.
// Пользователь отправляет /bind боту -> получает код,
// админ вводит код в веб-интерфейсе -> telegramId связывается с аккаунтом.

const TTL_MS = 10 * 60 * 1000; // коды живут 10 минут
const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // без I, L, O, 0, 1
const codes = new Map(); // code -> { telegramId, createdAt }

function createCode(telegramId) {
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
  }
  codes.set(code, { telegramId, createdAt: Date.now() });
  return code;
}

function redeemCode(code) {
  const key = String(code || '').trim().toUpperCase();
  const entry = codes.get(key);
  if (!entry || Date.now() - entry.createdAt > TTL_MS) return null;
  codes.delete(key);
  return entry; // { telegramId }
}

module.exports = { createCode, redeemCode };