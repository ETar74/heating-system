#!/usr/bin/env bash
#
# setup-cloud.sh — первичная настройка облачного VPS (Ubuntu/Debian, x86_64)
# под heating-system.
#
# Что делает (идемпотентно — повторный запуск безопасен):
#   1. apt: curl, ca-certificates, ufw, fail2ban, unattended-upgrades
#   2. Docker Engine + Compose plugin (get.docker.com)
#   3. UFW: открыть SSH-порт, 3000 (backend), 5173 (frontend);
#      явно закрыть 5433 (postgres — наружу не публикуется никогда)
#   4. fail2ban (jail sshd) + автообновления (unattended-upgrades)
#   5. вызывающий пользователь (sudo) добавляется в группу docker;
#      опционально создаётся новый пользователь (--user)
#
# Использование:
#   sudo ./scripts/setup-cloud.sh [options]
#
# Опции:
#   --user NAME    создать пользователя NAME (sudo + docker группа)
#   --ssh-port N   порт SSH, открываемый в UFW (по умолчанию: 22)
#   --tz ZONE      часовой пояс, например Asia/Novosibirsk
#   --yes          не спрашивать про включение UFW
#   -h, --help     справка
#
# Дальше (см. README, раздел «Деплой в облачный VPS»):
#   cd /opt/heating-system
#   cp .env.cloud .env && nano .env
#   docker compose up -d --build
#   curl http://<публичный-IP>:3000/health
set -euo pipefail

SSH_PORT=22
TZ_ZONE=""
NEW_USER=""
NO_ASK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)     NEW_USER="${2:?"--user требует значение"}"; shift 2 ;;
    --ssh-port) SSH_PORT="${2:?"--ssh-port требует значение"}"; shift 2 ;;
    --tz)       TZ_ZONE="${2:?"--tz требует значение"}"; shift 2 ;;
    --yes)      NO_ASK=1; shift ;;
    -h|--help)
      cat <<'HELP'
Использование: sudo ./scripts/setup-cloud.sh [options]

Опции:
  --user NAME    создать пользователя NAME (sudo + docker группа)
  --ssh-port N   порт SSH, открываемый в UFW (по умолчанию: 22)
  --tz ZONE      часовой пояс, например Asia/Novosibirsk
  --yes          не спрашивать про включение UFW
  -h, --help     справка
HELP
      exit 0 ;;
    *) echo "Неизвестный аргумент: $1 (см. --help)" >&2; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Запустите через sudo: sudo $0 $*" >&2
  exit 1
fi

if ! grep -Eq '^(ID=ubuntu|ID=debian)$' /etc/os-release; then
  echo "Поддерживаются только Ubuntu/Debian: $(. /etc/os-release && echo "$PRETTY_NAME")" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "== 1/6 Системные пакеты =="
apt-get update -qq
apt-get install -y -qq curl ca-certificates ufw fail2ban unattended-upgrades

echo "== 2/6 Docker =="
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

echo "== 3/6 Часовой пояс =="
if [[ -n "$TZ_ZONE" ]]; then
  ln -sf "/usr/share/zoneinfo/$TZ_ZONE" /etc/localtime
  echo "$TZ_ZONE" > /etc/timezone
  echo "   Часовой пояс: $TZ_ZONE"
else
  echo "   Без изменений ($(date +%Z))"
fi

echo "== 4/6 UFW =="
ufw allow "$SSH_PORT"/tcp comment 'SSH'
ufw allow 3000/tcp  comment 'heating-system backend'
ufw allow 5173/tcp  comment 'heating-system frontend'
ufw deny 5433/tcp   comment 'postgres host-port — наружу не публикуется'
if [[ -z "$NO_ASK" && -t 0 ]]; then
  ufw enable      # в интерактиве спросит "Proceed with operation?"
else
  ufw --force enable
fi

echo "== 5/6 Fail2ban + автообновления =="
systemctl enable --now fail2ban
systemctl enable --now apt-daily.timer 2>/dev/null || true

echo "== 6/6 Группа docker =="
if [[ -n "$NEW_USER" ]]; then
  if id -u "$NEW_USER" >/dev/null 2>&1; then
    echo "   Пользователь $NEW_USER уже существует"
  else
    useradd -m -s /bin/bash "$NEW_USER"
    echo "   Создан пользователь $NEW_USER — задайте пароль: sudo passwd $NEW_USER"
  fi
  usermod -aG sudo,docker "$NEW_USER"
fi
if [[ -n "${SUDO_USER:-}" ]] && ! id -nG "$SUDO_USER" | grep -qw docker; then
  usermod -aG docker "$SUDO_USER"
  echo "   $SUDO_USER добавлен в группу docker (вступит в силу после переподключения SSH)"
fi

ufw status verbose

cat <<'EOF'

=========================== ГОТОВО ============================
Дальше:
  1. cd /opt/heating-system
  2. cp .env.cloud .env && nano .env    # JWT_SECRET, ESP32_TOKEN, публичный IP
  3. docker compose up -d --build
  4. curl http://<публичный-IP>:3000/health     # -> {"status":"ok","db":true}

UI: http://<публичный-IP>:5173
Открытые порты: SSH, 3000 (API), 5173 (UI). 5433 (postgres) закрыт.
Бэкап (cron):
  30 3 * * * BACKUP_DIR=/var/backups/heating \
    /opt/heating-system/scripts/backup-db.sh >> /var/backups/heating/backup.log 2>&1
==============================================================
EOF
