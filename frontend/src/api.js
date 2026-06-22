import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL 
  ? `${import.meta.env.VITE_API_URL}/api` 
  : 'http://localhost:3000/api';

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
    if (error.response?.status === 401 || error.response?.status === 403) {
      localStorage.removeItem('token');
      window.location.href = '/login';
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