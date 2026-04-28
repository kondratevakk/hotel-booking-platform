#!/bin/bash
set -e

migrate -path /app/migrations -database "$TEST_DB_URL" down 1
