#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-'EOSQL'
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'exporter') THEN
            CREATE ROLE exporter WITH LOGIN PASSWORD 'exporter_pass';
        END IF;
    END
    $$;

    GRANT pg_monitor TO exporter;
    GRANT CONNECT ON DATABASE hotel_booking TO exporter;
EOSQL
