# 📋 Контекст проекта "Система управления отоплением"

## 🎯 О проекте

Умная система управления гибридным отоплением частного дома на базе ESP32.
Позволяет контролировать твердотопливный и электрокотёл, тёплые полы, радиаторы и теплоаккумулятор.

**Автор:** ETar74  
**Репозиторий:** https://github.com/ETar74/heating-system

---

## 🏗️ Архитектура проекта

### Технологический стек

| Компонент | Технология | Порт |
|-----------|-----------|------|
| **Frontend** | React + Vite | 5173 |
| **Backend** | Node.js + Express (монолит) | 3000 |
| **Database** | PostgreSQL 16 | 5433 |
| **Real-time** | WebSocket (ws) | 3000 |
| **Telegram Bot** | node-telegram-bot-api (встроен в backend) | - |
| **ORM** | Prisma | - |
| **Деплой** | Docker + Docker Compose | - |

### Структура папок
heating-system/
├── backend/
│ └── src/
│ └── server.js ← ГЛАВНЫЙ ФАЙЛ (всё в одном: API, WebSocket, Telegram-бот)
│
├── frontend/
│ └── src/
│ ├── App.jsx ← Главный компонент, маршрутизация
│ ├── api.js ← Axios + интерсепторы (401/403)
│ ├── pages/
│ │ ├── Dashboard.jsx ← Главная панель
│ │ ├── Settings.jsx ← Настройки системы
│ │ ├── Users.jsx ← Управление пользователями
│ │ ├── Events.jsx ← Журнал событий
│ │ └── Login.jsx ← Авторизация
│ ├── components/
│ │ ├── Layout.jsx ← Общий макет (меню + контент)
│ │ ├── TempWidget.jsx ← Виджет температуры с трекером
│ │ └── MobileMenu.jsx
│ └── utils/
│ └── permissions.js ← Проверка ролей (canEditSettings и т.д.)
│
├── docker-compose.yml ← Конфигурация Docker
├── PROJECT_CONTEXT.md ← ЭТОТ ФАЙЛ
└── README.md

---

## 👥 Роли и права доступа (RBAC)

| Роль | Описание |
|------|----------|
| **ADMIN** | Полный доступ ко всему |
| **OPERATOR** | Управление настройками и устройствами |
| **VIEWER** | Только просмотр |

### Матрица прав

| Функция | ADMIN | OPERATOR | VIEWER |
|---------|:-----:|:--------:|:------:|
| Просмотр главной панели | ✅ | ✅ | ✅ |
| Просмотр событий | ✅ | ✅ | ✅ |
| Изменение настроек | ✅ | ✅ | ❌ |
| Управление котлом/насосами | ✅ | ✅ | ❌ |
| Просмотр пользователей | ✅ | ❌ | ❌ |
| Создание/редактирование пользователей | ✅ | ❌ | ❌ |
| Удаление пользователей | ✅ | ❌ | ❌ |
| Telegram-команды управления | ✅ | ✅ | ❌ |
| Telegram-команды просмотра | ✅ | ✅ | ✅ |

---

## ✅ Что УЖЕ сделано

### Бэкенд (`server.js`)
- ✅ Middleware `authenticateToken` — проверка JWT
- ✅ Middleware `requireRole` — проверка ролей (читает из JWT)
- ✅ Защита `/api/users` (GET/POST/PUT/DELETE) — только ADMIN
- ✅ Защита `/api/settings/:key` (PUT) — ADMIN + OPERATOR
- ✅ Защита `/api/settings` (PUT) — ADMIN + OPERATOR
- ✅ Защита `/api/commands` (POST) — ADMIN + OPERATOR
- ✅ Telegram-бот: проверка ролей для команд управления

### Фронтенд
- ✅ Обработка 401 → редирект на логин
- ✅ Обработка 403 → alert с ошибкой (без редиректа)
- ✅ Сохранение `user` в localStorage (для проверки ролей на фронте)
- ✅ Утилита `utils/permissions.js` с функциями `canEditSettings`, `canManageUsers`, `canControlDevices`
- ✅ `Settings.jsx`: скрытие кнопок ✏️💾❌ для VIEWER, показ "Только просмотр"
- ✅ Правильный порядок колонок в таблице настроек: Параметр → Значение → Действия

### UI/UX
- ✅ Двухколоночная сетка на странице настроек
- ✅ Уменьшенные карточки на главной панели (size-sm, size-lg, size-xs)
- ✅ Адаптивные мобильные карточки для пользователей
- ✅ Форма редактирования пользователей с подписями полей
- ✅ Индикатор температуры в виде прямоугольника с чёрточкой

### Инфраструктура
- ✅ Проект на GitHub (https://github.com/ETar74/heating-system)
- ✅ Docker Compose для деплоя
- ✅ Настроены volumes для hot reload

---

## ⬜ Что НУЖНО сделать

### Приоритет: ВЫСОКИЙ 🔴

1. **UI-защита для VIEWER в настройках**
   - Сделать поля ввода `disabled` для VIEWER
   - Добавить визуальную индикацию "режим только чтения"

2. **Telegram-бот: разграничение команд**
   - Команды просмотра (`/status`, `/events`, `/settings`) — всем
   - Команды управления (`/boiler_on`, `/floor_pump_on`) — только ADMIN + OPERATOR
   - Проверка привязки Telegram ID к пользователю

### Приоритет: СРЕДНИЙ 🟡

3. **Dashboard.jsx: защита элементов управления**
   - Скрыть/заблокировать кнопки управления устройствами для VIEWER
   - Показывать уведомления о недостатке прав

4. **Events.jsx: просмотр для всех ролей**
   - Убедиться, что все роли могут просматривать события

### Приоритет: НИЗКИЙ 🟢

5. **Улучшения UI**
   - Тёмная тема
   - Улучшение графиков
   - Адаптация для планшетов

6. **Документация**
   - README с инструкциями по установке
   - Скриншоты интерфейса

---

## 🔑 Ключевые файлы для работы

### При изменении прав доступа:
- `backend/src/server.js` — middleware `requireRole` и роуты
- `frontend/src/utils/permissions.js` — функции проверки ролей
- `frontend/src/api.js` — обработка ошибок 401/403

### При изменении UI:
- `frontend/src/pages/Settings.jsx` — страница настроек
- `frontend/src/pages/Dashboard.jsx` — главная панель
- `frontend/src/components/TempWidget.jsx` — виджеты температур

### При работе с Telegram-ботом:
- `backend/src/server.js` — секция с `bot.onText(...)`

---

## 🐛 Известные проблемы

1. **VIEWER видит активные поля в настройках**
   - Статус: В процессе решения
   - Решение: добавить `disabled` к input/select

2. **Telegram-бот не проверяет роли для некоторых команд**
   - Статус: Требуется реализация
   - Нужно добавить проверку `user.role.name` перед выполнением

---

## 🛠 Команды для разработки

```bash
# Пересобрать всё
docker-compose up -d --build

# Пересобрать только backend
docker-compose up -d --build backend

# Пересобрать только frontend
docker-compose up -d --build frontend

# Посмотреть логи
docker-compose logs -f backend
docker-compose logs -f frontend

# Остановить всё
docker-compose down

# Зайти внутрь контейнера
docker-compose exec backend sh
