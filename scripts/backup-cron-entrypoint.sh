#!/bin/bash
set -euo pipefail

BACKUP_INTERVAL="${BACKUP_INTERVAL:-0 2 * * *}"

printenv | grep -v "no_proxy" > /etc/environment

echo "${BACKUP_INTERVAL} root . /etc/environment && /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1" > /etc/cron.d/backup-cron
chmod 0644 /etc/cron.d/backup-cron
crontab /etc/cron.d/backup-cron

/usr/local/bin/backup.sh || echo "[$(date)] Initial backup failed, will retry on schedule."

echo "[$(date)] Cron started: ${BACKUP_INTERVAL}"
cron -f
