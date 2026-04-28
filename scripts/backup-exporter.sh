#!/bin/bash
set -euo pipefail

METRICS_FILE="${METRICS_FILE:-/var/backup-metrics/backup_metrics.txt}"
PORT="${EXPORTER_PORT:-9199}"

DEFAULT_METRICS='# HELP backup_last_success_timestamp_seconds Unix timestamp of the last successful backup.
# TYPE backup_last_success_timestamp_seconds gauge
backup_last_success_timestamp_seconds 0
# HELP backup_last_size_bytes Size of the last backup in bytes.
# TYPE backup_last_size_bytes gauge
backup_last_size_bytes 0
# HELP backup_count Total number of backups currently stored.
# TYPE backup_count gauge
backup_count 0'

while true; do
    if [ -f "$METRICS_FILE" ]; then
        METRICS=$(cat "$METRICS_FILE")
    else
        METRICS="$DEFAULT_METRICS"
    fi

    CONTENT_LENGTH=$(echo "$METRICS" | wc -c | tr -d ' ')

    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: ${CONTENT_LENGTH}\r\nConnection: close\r\n\r\n${METRICS}" | nc -l -p "$PORT" -q 1 > /dev/null 2>&1 || true
done
