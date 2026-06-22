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
# 🔥 Система управления отоплением

Умная система управления гибридным отоплением частного дома на базе ESP32.

## 📸 Скриншоты

![Главная панель](docs/screenshots/dashboard.png)
![Настройки](docs/screenshots/settings.png)

## ✨ Возможности

- 🌡️ Мониторинг температуры в реальном времени
- 🔥 Управление твердотопливным и электрокотлом
- 💧 Контроль теплых полов и радиаторов
- 📊 Графики и история изменений
- 📱 Мобильная версия интерфейса
- 🤖 Уведомления через Telegram-бот

## 🛠 Технологии

| Компонент | Технология |
|-----------|-----------|
| Frontend | React, CSS |
| Backend | Node.js, Express |
| Database | PostgreSQL, Prisma |
| Real-time | WebSocket |
| Hardware | ESP32 |
| Deployment | Docker |

## 🚀 Быстрый старт

### Требования
- Docker и Docker Compose
- Git

### Установка

```bash
# Клонировать репозиторий
git clone https://github.com/ETar74/heating-system.git

# Перейти в папку проекта
cd heating-system

# Запустить все сервисы
docker-compose up -d --build