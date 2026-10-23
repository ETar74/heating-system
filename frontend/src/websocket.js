const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';
// Преобразуем http:// в ws://
const WS_URL = API_URL.replace(/^http/, 'ws');

let socket = null;
let reconnectTimer = null;

export function initWebSocket() {
  const token = localStorage.getItem('token');
  if (!token) {
    console.warn('[WS] No token, skipping connection');
    return;
  }

  // Подключаемся, передавая токен в URL
  socket = new WebSocket(`${WS_URL}?token=${encodeURIComponent(token)}`);

  socket.onopen = () => {
    console.log('[WS] ✅ Connected to server');
    clearTimeout(reconnectTimer);
  };

  socket.onclose = (event) => {
    console.warn(`[WS] ❌ Disconnected (code: ${event.code}). Reconnecting in 3s...`);
    socket = null;
    reconnectTimer = setTimeout(initWebSocket, 3000);
  };

  socket.onerror = (error) => {
    console.error('[WS] Error:', error);
  };

  socket.onmessage = (event) => {
    try {
      const message = JSON.parse(event.data);
      console.log('[WS] 📩 Received:', message.event);

      // Генерируем CustomEvent, чтобы любой компонент мог на него подписаться
      window.dispatchEvent(new CustomEvent(`ws:${message.event}`, { detail: message.data }));
    } catch (e) {
      console.error('[WS] Failed to parse message:', e);
    }
  };
}

export function disconnectWebSocket() {
  if (socket) {
    socket.close();
    socket = null;
    clearTimeout(reconnectTimer);
  }
}

export function sendToServer(event, data) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify({ event, data }));
  }
}