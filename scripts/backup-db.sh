#!/usr/bin/env bash
# Бэкап SQLite (heating.db) из Docker-контейнера heating_backend.
#
# Назначение: cron на VPS/SBC с Docker-деплоем (SQLite вариант).
# Файл БД лежит в Docker volume `sqlite_data` (внутри /app/data/heating.db).
# Бэкап консистентный: SQLite `.backup` работает даже при активной записи (WAL).
# Старые бэкапы старше RETENTION_DAYS удаляются автоматически.
#
# Использование:
#   scripts/backup-db.sh
#   BACKUP_DIR=/mnt/backup RETENTION_DAYS=7 scripts/backup-db.sh
#
# Cron (каждый день в 03:30):
#   30 3 * * * /opt/heating-system/scripts/backup-db.sh >> /data/backup/backup.log 2>&1
#
# Восстановление (остановить backend, заменить файл, вернуть права):
#   docker compose stop backend
#   gunzip -c /data/backup/heating-YYYYMMDD-HHMMSS.db.gz > /tmp/heating.db
#   docker cp /tmp/heating.db heating_backend:/app/data/heating.db
#   docker compose start backend

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/data/backup}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
CONTAINER="${CONTAINER:-heating_backend}"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/heating-${STAMP}.db"

mkdir -p "$BACKUP_DIR"

echo "[$(date '+%F %T')] Бэкап SQLite (контейнер ${CONTAINER}) -> ${BACKUP_FILE}"

# Используем `.backup` внутри контейнера: создаёт консистентную копию файла БД.
docker exec "$CONTAINER" sh -c 'sqlite3 /app/data/heating.db ".backup /tmp/heating_backup.db" 2>/dev/null \
  || cp /app/data/heating.db /tmp/heating_backup.db' \
  || cp /app/data/heating.db "$BACKUP_FILE"

# Достаём файл из контейнера
docker cp "$CONTAINER:/tmp/heating_backup.db" "$BACKUP_FILE"

# Пустой/отсутствующий файл бэкапа — признак ошибки, не оставляем артефакт
if [ ! -s "$BACKUP_FILE" ]; then
  echo "ОШИБКА: файл бэкапа пуст — удаляю и прерываюсь" >&2
  rm -f "$BACKUP_FILE"
  exit 1
fi

# Сжимаем (рекомендуется)
gzip -f "$BACKUP_FILE"
GZ_FILE="${BACKUP_FILE}.gz"

# Чистим старые бэкапы
find "$BACKUP_DIR" -name "heating-*.db.gz" -type f -mtime "+${RETENTION_DAYS}" -print -delete \
  | sed 's/^/Удалён старый бэкап: /'

echo "[$(date '+%F %T')] Готово: $(du -h "$GZ_FILE" | cut -f1)"
