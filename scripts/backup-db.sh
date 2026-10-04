#!/usr/bin/env bash
# Бэкап PostgreSQL (heating_system) из Docker-контейнера heating_postgres.
#
# Назначение: cron на SBC (Orange Pi 3B) или любом хосте с Docker.
# Копится в BACKUP_DIR (по умолчанию /data/backup), старые бэкапы
# старше RETENTION_DAYS дней удаляются автоматически.
#
# Использование:
#   scripts/backup-db.sh
#   BACKUP_DIR=/mnt/backup RETENTION_DAYS=7 scripts/backup-db.sh
#
# Cron (каждый день в 03:30):
#   30 3 * * * /opt/heating-system/scripts/backup-db.sh >> /data/backup/backup.log 2>&1
#
# Восстановление:
#   gunzip -c /data/backup/heating_system-YYYYMMDD-HHMMSS.sql.gz \
#     | docker exec -i heating_postgres psql -U postgres heating_system

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/data/backup}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
DB_NAME="${DB_NAME:-heating_system}"
DB_USER="${DB_USER:-postgres}"
CONTAINER="${CONTAINER:-heating_postgres}"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}-${STAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "[$(date '+%F %T')] Бэкап '${DB_NAME}' -> ${BACKUP_FILE}"
docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

# Пустой файл бэкапа — признак ошибки, не оставляем артефакт
if [ ! -s "$BACKUP_FILE" ]; then
  echo "ОШИБКА: файл бэкапа пуст — удаляю и прерываюсь" >&2
  rm -f "$BACKUP_FILE"
  exit 1
fi

# Чистим старые бэкапы
find "$BACKUP_DIR" -name "${DB_NAME}-*.sql.gz" -type f -mtime "+${RETENTION_DAYS}" -print -delete \
  | sed 's/^/Удалён старый бэкап: /'

echo "[$(date '+%F %T')] Готово: $(du -h "$BACKUP_FILE" | cut -f1)"
