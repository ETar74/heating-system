import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: '0.0.0.0',
    allowedHosts: ['80-66-89-208.nip.io', 'localhost', '127.0.0.1'], // <-- ДОБАВЬ ЭТУ СТРОКУ
    proxy: {
      '/api': {
        target: 'http://backend:3000',
        changeOrigin: true
      },
      '/ws': {
        target: 'ws://backend:3000',
        ws: true
      }
    }
  }
})