import axios from 'axios';

// Базовый URL API (без хвостового /api и /)
const API_BASE = (import.meta.env.VITE_API_URL || 'http://localhost:3000').replace(/\/+$/, '');

const API_URL = `${API_BASE}/api`;

// Адрес WebSocket: тот же host/port, что и API (http → ws, https → wss)
export const WS_URL = API_BASE.replace(/^http/, 'ws');

const api = axios.create({
  baseURL: API_URL
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      // 401 - токен истёк или невалиден → мягкий логин:
      // App.jsx поймает событие и перекинет на /login БЕЗ перезагрузки страницы
      if (error.response.status === 401) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.dispatchEvent(new CustomEvent('auth:unauthorized'));
        return Promise.reject(error);
      }
      
      // 403 - нет прав → НЕ выбрасываем на логин, просто показываем ошибку
      if (error.response.status === 403) {
        const message = error.response.data?.error || 'Доступ запрещен. Недостаточно прав.';
        alert(`❌ ${message}`);
        return Promise.reject(error);
      }
    }
    return Promise.reject(error);
  }
);

export const auth = {
  login: (username, password) => api.post('/auth/login', { username, password }),
  logout: () => api.post('/auth/logout'),
  me: () => api.get('/auth/me')
};

export const users = {
  getAll: () => api.get('/users'),
  create: (data) => api.post('/users', data),
  update: (id, data) => api.put(`/users/${id}`, data),
  delete: (id) => api.delete(`/users/${id}`)
};

export const telemetry = {
  getLatest: () => api.get('/telemetry/latest'),
  getHistory: (params) => api.get('/telemetry/history', { params })
};

export const settings = {
  getAll: () => api.get('/settings'),
  update: (parameters) => api.put('/settings', { parameters })
};

export const events = {
  getAll: (limit = 100) => api.get('/events', { params: { limit } })
};

export const commands = {
  send: (command, payload = {}) => api.post('/commands', { command, payload }),
  getPending: () => api.get('/commands/pending')
};

export default api;