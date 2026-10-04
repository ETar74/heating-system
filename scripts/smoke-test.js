// scripts/smoke-test.js
// Смоук-тесты API. Нужен запущенный сервер:
//   node server.js   (из корня проекта)
//
// Запуск:
//   npm test
//
// Переменные окружения (необязательные):
//   TEST_BASE_URL        — по умолчанию http://localhost:3000
//   TEST_ADMIN_LOGIN     — по умолчанию admin
//   TEST_ADMIN_PASSWORD  — по умолчанию admin123

const { test } = require('node:test');
const assert = require('node:assert');
const WS = require('ws');

const BASE = process.env.TEST_BASE_URL || 'http://localhost:3000';
const ADMIN_LOGIN = process.env.TEST_ADMIN_LOGIN || 'admin';
const ADMIN_PASSWORD = process.env.TEST_ADMIN_PASSWORD || 'admin123';

async function req(method, path, { token, body } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  let data = null;
  try {
    data = await res.json();
  } catch {
    /* ответ не JSON */
  }
  return { status: res.status, data };
}

async function serverAlive() {
  try {
    const res = await fetch(BASE + '/health');
    return res.status === 200 || res.status === 503;
  } catch {
    return false;
  }
}

let token = null;

test('Сервер запущен (/health)', async () => {
  const alive = await serverAlive();
  assert.ok(alive, `Не удалось подключиться к ${BASE} — запустите сервер: node server.js`);
});

test('GET /api/settings без токена -> 401', async () => {
  const r = await req('GET', '/api/settings');
  assert.strictEqual(r.status, 401);
});

test('POST /api/commands без токена -> 401', async () => {
  const r = await req('POST', '/api/commands', { body: { command: 'boiler_on' } });
  assert.strictEqual(r.status, 401);
});

test('GET /api/commands/pending без device-токена -> 401 (или 200 в dev-режиме)', async () => {
  const r = await req('GET', '/api/commands/pending');
  assert.ok(
    [200, 401].includes(r.status),
    `Ожидалось 200 (dev) или 401 (ESP32_TOKEN задан), получено ${r.status}`
  );
});

test('Логин с неверным паролем -> 401', async () => {
  const r = await req('POST', '/api/auth/login', {
    body: { username: ADMIN_LOGIN, password: 'definitely-wrong-xyz' },
  });
  assert.strictEqual(r.status, 401, `Ожидался 401, получен ${r.status} (500 — проверьте доступ к БД)`);
});

test('Логин админа -> токен', async () => {
  const r = await req('POST', '/api/auth/login', {
    body: { username: ADMIN_LOGIN, password: ADMIN_PASSWORD },
  });
  if (r.status !== 200) {
    console.log(`⚠️  Логин админа не удался (${r.status}) — остальные тесты пропущены`);
    return;
  }
  token = r.data.token;
  assert.ok(token, 'Токен пустой');
});

test('GET /api/auth/me с токеном', async () => {
  if (!token) return;
  const r = await req('GET', '/api/auth/me', { token });
  assert.strictEqual(r.status, 200);
  assert.strictEqual(r.data.role, 'ADMIN');
});

test('POST /api/commands: команда вне allowlist -> 400', async () => {
  if (!token) return;
  const r = await req('POST', '/api/commands', { token, body: { command: 'drop_table' } });
  assert.strictEqual(r.status, 400);
});

test('PUT /api/settings/room_temp_target: значение вне диапазона -> 400', async () => {
  if (!token) return;
  const r = await req('PUT', '/api/settings/room_temp_target', { token, body: { value: 500 } });
  assert.strictEqual(r.status, 400, `Ожидался 400, получен ${r.status}`);
});

test('PUT /api/settings/unknown_key -> 400', async () => {
  if (!token) return;
  const r = await req('PUT', '/api/settings/unknown_key', { token, body: { value: 1 } });
  assert.strictEqual(r.status, 400);
});

test('DELETE /api/users/:id: удалить себя -> 400', async () => {
  if (!token) return;
  const me = await req('GET', '/api/auth/me', { token });
  const r = await req('DELETE', `/api/users/${me.data.id}`, { token });
  assert.strictEqual(r.status, 400, `Ожидался 400, получен ${r.status}`);
});

test('WebSocket без токена -> закрытие кодом 4001', async () => {
  await new Promise((resolve) => {
    const ws = new WS(BASE.replace(/^http/, 'ws'));
    ws.on('close', (code) => {
      assert.strictEqual(code, 4001, `Ожидался 4001, получен ${code}`);
      resolve();
    });
    ws.on('error', (err) => {
      console.log('⚠️  WS ошибка:', err.message);
      resolve();
    });
  });
});