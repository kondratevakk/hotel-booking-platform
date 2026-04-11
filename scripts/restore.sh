#!/bin/bash
set -euo pipefail

MINIO_ENDPOINT="${MINIO_ENDPOINT:-minio:9000}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin}"
BUCKET="${BUCKET_BACKUP_NAME:-hotel-backups}"

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-hotel_booking}"
DB_USER="${POSTGRES_USER:-hotel_user}"

TMP_DIR="/tmp/backups"
mkdir -p "$TMP_DIR"

mc alias set myminio "http://${MINIO_ENDPOINT}" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" --api S3v4 > /dev/null

if [ -z "${BACKUP_FILE:-}" ]; then
    BACKUP_FILE=$(mc ls "myminio/${BUCKET}/" | grep "backup_${DB_NAME}_" | sort -k6 | tail -1 | awk '{print $NF}')
    if [ -z "$BACKUP_FILE" ]; then
        echo "ERROR: No backups found in bucket '${BUCKET}'"
        exit 1
    fi
fi

echo "[$(date)] Restoring '${DB_NAME}' from ${BACKUP_FILE}..."
mc cp "myminio/${BUCKET}/${BACKUP_FILE}" "${TMP_DIR}/${BACKUP_FILE}" > /dev/null

export PGPASSWORD="${POSTGRES_PASSWORD}"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -qc "
    SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();
" > /dev/null
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -qc "DROP DATABASE IF EXISTS \"${DB_NAME}\";"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -qc "CREATE DATABASE \"${DB_NAME}\";"

gunzip -c "${TMP_DIR}/${BACKUP_FILE}" | psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null

rm -f "${TMP_DIR}/${BACKUP_FILE}"

echo "[$(date)] Restore done from ${BACKUP_FILE}."
