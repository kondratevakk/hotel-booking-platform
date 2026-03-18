#!/bin/bash
set -e

MIG_FILE=$(basename "$1")
VERSION=$(echo "$MIG_FILE" | grep -oE '^[0-9]+')
VERSION_INT=$((10#$VERSION))

migrate -path /app/migrations -database "$TEST_DB_URL" goto "$VERSION_INT"
