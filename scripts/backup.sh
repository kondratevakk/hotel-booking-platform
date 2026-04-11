#!/bin/bash
set -euo pipefail

MINIO_ENDPOINT="${MINIO_ENDPOINT:-minio:9000}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin}"
BUCKET="${BUCKET_BACKUP_NAME:-hotel-backups}"
RETENTION="${BACKUP_RETENTION_COUNT:-7}"
METRICS_FILE="${METRICS_FILE:-/var/backup-metrics/backup_metrics.txt}"

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-hotel_booking}"
DB_USER="${POSTGRES_USER:-hotel_user}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${DB_NAME}_${TIMESTAMP}.sql.gz"
TMP_DIR="/tmp/backups"

mkdir -p "$TMP_DIR" "$(dirname "$METRICS_FILE")"

echo "[$(date)] Starting backup of '${DB_NAME}'..."

mc alias set myminio "http://${MINIO_ENDPOINT}" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" --api S3v4 > /dev/null

if ! mc ls "myminio/${BUCKET}" > /dev/null 2>&1; then
    mc mb "myminio/${BUCKET}" > /dev/null
fi

export PGPASSWORD="${POSTGRES_PASSWORD}"
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" | gzip > "${TMP_DIR}/${BACKUP_FILE}"

BACKUP_SIZE=$(stat -c%s "${TMP_DIR}/${BACKUP_FILE}" 2>/dev/null || stat -f%z "${TMP_DIR}/${BACKUP_FILE}")

mc cp "${TMP_DIR}/${BACKUP_FILE}" "myminio/${BUCKET}/${BACKUP_FILE}" > /dev/null

BACKUPS=$(mc ls "myminio/${BUCKET}/" | grep "backup_${DB_NAME}_" | sort -k6 | awk '{print $NF}')
TOTAL=$(echo "$BACKUPS" | grep -c . || true)

if [ "$TOTAL" -gt "$RETENTION" ]; then
    DELETE_COUNT=$((TOTAL - RETENTION))
    echo "$BACKUPS" | head -n "$DELETE_COUNT" | while read -r old_backup; do
        mc rm "myminio/${BUCKET}/${old_backup}" > /dev/null
    done
fi

rm -f "${TMP_DIR}/${BACKUP_FILE}"

BACKUP_TIMESTAMP=$(date +%s)
cat > "$METRICS_FILE" <<EOF
# HELP backup_last_success_timestamp_seconds Unix timestamp of the last successful backup.
# TYPE backup_last_success_timestamp_seconds gauge
backup_last_success_timestamp_seconds ${BACKUP_TIMESTAMP}
# HELP backup_last_size_bytes Size of the last backup in bytes.
# TYPE backup_last_size_bytes gauge
backup_last_size_bytes ${BACKUP_SIZE}
# HELP backup_count Total number of backups currently stored.
# TYPE backup_count gauge
backup_count $((TOTAL > RETENTION ? RETENTION : TOTAL))
EOF

echo "[$(date)] Backup done: ${BACKUP_FILE} (${BACKUP_SIZE} bytes), ${TOTAL} stored."
