# Система управления отоплением

Платформа управления отоплением на базе ESP32 с веб-интерфейсом и Telegram-ботом.

## Установка и запуск

### 1. Установка зависимостей
cd heating-system
npm install

### 2. Настройка базы данных
Отредактируйте .env и выполните:
npx prisma db push

### 3. Запуск сервера
npm run dev

### 4. Запуск фронтенда
cd frontend
npm install
npm run dev

## Доступ
- Frontend: http://localhost:5173
- Логин: admin
- Пароль: admin123