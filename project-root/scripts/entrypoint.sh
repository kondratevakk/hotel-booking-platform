#!/bin/bash
set -e

until pg_isready -d "$MAIN_DB_URL" > /dev/null 2>&1; do
    sleep 2
done

migrate -path ./migrations -database "$TEST_DB_URL" up 1 > /dev/null 2>&1 || true
migrate -path ./migrations -database "$TEST_DB_URL" down 1 > /dev/null 2>&1 || true

mkdir -p /tmp/seqwall_migrations
cp ./migrations/*.up.sql /tmp/seqwall_migrations/

seqwall staircase \
    --postgres-url "$TEST_DB_URL" \
    --migrations-path /tmp/seqwall_migrations \
    --upgrade "/app/scripts/ci-up-one.sh {current_migration}" \
    --downgrade "/app/scripts/ci-down-one.sh {current_migration}"

if [ -n "$MIGRATION_VERSION" ]; then
    migrate -path ./migrations -database "$MAIN_DB_URL" goto "$MIGRATION_VERSION"
else
    migrate -path ./migrations -database "$MAIN_DB_URL" up
fi

echo "Migrations applied."

if [ "$APP_ENV" != "prod" ]; then
    CURRENT_VERSION=$(migrate -path ./migrations -database "$MAIN_DB_URL" version 2>&1 || echo "0")

    psql "$MAIN_DB_URL" \
        -v ON_ERROR_STOP=1 \
        -v SEED_COUNT="${SEED_COUNT:-1}" \
        -v SCHEMA_VERSION="$CURRENT_VERSION" \
        -f ./seeds/seed.sql

fi

echo "Done."