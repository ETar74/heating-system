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
```

Сервисы:
| Что | Адрес |
|-----|-------|
| Веб-интерфейс | http://localhost:5173 |
| API / WebSocket | http://localhost:3000 |
| PostgreSQL (из хоста) | localhost:5433 |
| Prisma Studio (dev) | http://localhost:5555 |
| PgAdmin (dev) | http://localhost:5050 |

> Dev-сервисы (Prisma Studio, PgAdmin) включены через `docker-compose.override.yml`.
> Для чистого продакшена: `docker-compose -f docker-compose.yml up -d`.

## 🔑 Доступ по умолчанию

- Логин: `admin`
- Пароль: `admin123`

⚠️ **Обязательно смените пароль** (страница «Пользователи») после первого запуска.

## 🧑‍💻 Разработка без Docker

```bash
# 1. Зависимости
npm install
cd frontend && npm install && cd ..

# 2. База данных (нужен локальный PostgreSQL)
npx prisma db push

# 3. Сервер (http://localhost:3000)
npm run dev

# 4. Фронтенд (http://localhost:5173)
cd frontend && npm run dev
```

## ⚙️ Конфигурация (.env)

| Переменная | Обяз. | Описание |
|------------|:-----:|----------|
| `DATABASE_URL` | ✅ | Строка подключения PostgreSQL |
| `JWT_SECRET` | ✅ | Секрет подписи JWT (случайные 32+ байт) |
| `TELEGRAM_BOT_TOKEN` | – | Токен Telegram-бота (без него бот выключен) |
| `PORT` | – | Порт API, по умолчанию 3000 |
| `ESP32_TOKEN` | – | Секрет устройства ESP32. Пусто = dev-режим (проверка отключена, лог с предупреждением) |
| `ESP32_ALLOWED_IPS` | – | Разрешённые IP ESP32 через запятую |
| `CORS_ORIGINS` | – | Разрешённые origins через запятую |
| `TELEMETRY_RETENTION_DAYS` | – | Сколько дней хранить сырую телеметрию (по умолчанию 30) |

## 📡 Подключение ESP32

Устройство раз в несколько секунд отправляет `POST /api/device/sync`
(пример payload: `scripts/test-sync.json`) и забирает команды через
`GET /api/commands/pending`. Выполненные команды подтверждает
`POST /api/device/command/:id/executed`.

Если задан `ESP32_TOKEN`, все эти запросы должны содержать токен:
- заголовок `Authorization: Bearer <токен>`, либо
- query-параметр `?token=<токен>`.

Обновление прошивки (OTA): админ загружает и одобряет файл на сервере,
устройство получает ссылку в ответе `sync` и скачивает
`GET /api/ota/download/:id`.

## 🖥 Развёртывание на SBC (Orange Pi 3B)

Сценарий «живого» сервера: **ОС на eMMC, вся статистика и Docker на SSD**, SD-карта не используется.

> ⚠️ Boot ROM у RK3566 стартует только с eMMC или SD (не с NVMe/SATA).
> Поэтому на OPi 3B без eMMC-модуля SD-карта остаётся обязательной (только как загрузчик).
> Вставной eMMC-модуль (34-pin разъём на задней стороне платы) — штатный вариант «без SD».

### Топология

| Носитель | Назначение |
|----------|-----------|
| eMMC 16–32 ГБ (модуль 34 pin) | ОС + `/boot`, записи минимальные |
| SSD 256 ГБ (M.2 NVMe / SATA) | `/data`: Docker (образа, контейнеры), PostgreSQL (телеметрия), бэкапы |

### Шаг 0. Железо
- eMMC-модуль (16–32 ГБ, «для Orange Pi 3B») — в 34-pin разъём на задней стороне платы;
- SSD — в M.2 (NVMe) или SATA;
- питание **5 В ≥ 3 А**; TF-карта с образом — в слоте (только на время установки).

### Шаг 1. Образ Armbian на TF-карте
1. [armbian.com → Orange Pi 3B](https://www.armbian.com/orange-pi-3b/) → **Debian 13 trixie Minimal (CLI)**, ядро `current` → `.img`.
2. Balena Etcher (Windows): *Flash from file* → `.img` → TF-карта 8–16 ГБ.
3. Первый запуск: логин `root` / пароль `1234`. Система сама расширит раздел и перезагрузится — это нормально.

### Шаг 2. Базовая настройка
```bash
passwd                                   # сменить пароль root
sudo adduser server                      # обычный пользователь для работы
sudo armbian-config                      # часовой пояс Europe/Moscow, язык ru-RU.UTF-8, SSH
sudo apt update && sudo apt full-upgrade -y && sudo reboot
```

### Шаг 3. Статический IP
Имя интерфейса смотрите `ip link` (обычно `end0`).
```bash
sudo nano /etc/netplan/01-static.yaml
```
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    end0:
      dhcp4: false
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8]
```
```bash
sudo netplan try && sudo reboot
```
Дальше по тексту **192.168.1.50** — статический IP Pi (подставьте свой, если другой).

### Шаг 4. Проверка носителей
```bash
lsblk
```
Ожидаемо: `/dev/mmcblk1` (eMMC), `/dev/nvme0n1` или `/dev/sda` (SSD).

### Шаг 5. Система на eMMC (и SD-карту можно вынуть)
```bash
sudo armbian-install          # выбрать /dev/mmcblk1 (eMMC), схема по умолчанию, ext4
sudo reboot
```
После перезагрузки: `df -h /` → `/dev/mmcblk1p2`. **TF-карту можно вынуть** — система дальше работает без неё.

### Шаг 6. SSD под /data
```bash
sudo parted /dev/nvme0n1 mklabel gpt
sudo parted /dev/nvme0n1 mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 /dev/nvme0n1p1
sudo mkdir -p /data
echo "UUID=$(sudo blkid -s UUID -o value /dev/nvme0n1p1)  /data  ext4  defaults,nofail  0 2" | sudo tee -a /etc/fstab
sudo mount /data && sudo mkdir -p /data/docker /data/backup
```
Docker хранит данные на SSD:
```bash
echo '{ "data-root": "/data/docker" }' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```
*(Если SSD на SATA — во всех командах вместо `/dev/nvme0n1` подставьте `/dev/sda`.)*

### Шаг 7. Docker
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker server
# в новой сессии от server:
docker run --rm hello-world        # проверка arm64-сборки
```

### Шаг 8. Приложение
```bash
git clone https://github.com/ETar74/heating-system.git /opt/heating-system
cd /opt/heating-system
cp .env.prod .env                  # заполнить JWT_SECRET, ESP32_TOKEN, IP Pi
sudo docker compose up -d --build  # сборка на самом Pi (arm64-Prisma!)
chmod +x scripts/backup-db.sh
```
> ⚠️ Не копируйте `node_modules` и `.env` с Windows — бинарные движки Prisma arm64 собираются только на самом Pi.

Проверки:
```bash
curl http://192.168.1.50:3000/health     # → {"status":"ok","db":true}
# UI: http://192.168.1.50:5173 (admin / admin123 → сменить пароль)
sudo docker compose logs -f heating_backend   # без ошибок Prisma
```

### Шаг 9. ESP32
В прошивке устройства:
- URL → `http://192.168.1.50:3000`
- токен → значение `ESP32_TOKEN` из `.env`

Синхронизация видна в UI и в логах backend.

### Обслуживание
- **Бэкап БД**: `scripts/backup-db.sh` (pg_dump → `/data/backup`, автоочистка по возрасту):
  ```bash
  crontab -e
  30 3 * * * /opt/heating-system/scripts/backup-db.sh >> /data/backup/backup.log 2>&1
  ```
- **ext4-гигиена**: `sudo systemctl enable fstrim.timer`
- **Автозапуск**: у всех сервисов compose `restart: unless-stopped` — после перезагрузки Pi контейнеры поднимутся сами.

### Доступ извне (опционально, итерация 2)
- **Tailscale** на Pi и на клиентах — приватная VPN-сеть без проброса портов:
  ```bash
  curl -fsSL https://tailscale.com/install.sh | sudo sh
  sudo tailscale up
  ```
  UI/SSH — по `http://<tailscale-ip>:5173` и т.д.
- Проброс портов роутера не рекомендуется (REST API достаточно в интранете).

### Чек-лист приёмки
- [ ] TF-карты нет в слоте; `df -h /` → `/dev/mmcblk1p2`, `df -h /data` → SSD
- [ ] `docker ps` — postgres, backend, frontend — `Up`
- [ ] `curl http://<ip>:3000/health` → `{"status":"ok","db":true}`
- [ ] UI открывается с другой машины, логин работает
- [ ] ESP32 синкается (логи backend, данные в UI)
- [ ] `sudo docker compose logs heating_backend` — без ошибок Prisma

## 🔐 Безопасность

- RBAC: ADMIN / OPERATOR / VIEWER (JWT, 24 ч).
- Изменение настроек блокируется, когда ESP32 офлайн (HTTP 423).
- Валидация значений настроек (диапазоны) и список разрешённых команд.
- Rate-limit на `/api/auth/login`, лимиты размера тела и загрузок.
- WebSocket требует валидный JWT (`?token=`).
- Не удаляется собственный аккаунт и последний ADMIN.

## 📚 Документация

- `API.md` — описание API
- `PROJECT_CONTEXT.md` — контекст и матрица прав
- `scripts/test-sync.json` — пример синка ESP32
