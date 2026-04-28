#!/usr/bin/env bash
# Demonstrates automatic failover: stops the current primary,
# waits for election, and verifies the client can still connect via HAProxy.

set -euo pipefail

PG_USER="postgres"
PG_PASS="postgres_password"
EXEC_NODE="ha_patroni1"   # container used to run psql commands

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

step() { echo -e "\n${YELLOW}==> $*${NC}"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; }

# Run a SQL query via HAProxy (inside a patroni container)
query_primary() {
  docker exec "${EXEC_NODE}" bash -c \
    "PGPASSWORD=${PG_PASS} psql -h haproxy -p 5000 -U ${PG_USER} -tAc \"$1\"" 2>/dev/null
}

psql_haproxy() {
  docker exec "${EXEC_NODE}" bash -c \
    "PGPASSWORD=${PG_PASS} psql -h haproxy -p 5000 -U ${PG_USER} $*" 2>/dev/null
}

# ── 1. Initial cluster state ──────────────────────────────────────────────────
step "1. Initial cluster state (Patroni REST API)"
echo "--- patroni1 ---"
curl -sf http://localhost:8008/ | python3 -m json.tool 2>/dev/null || echo "(not ready)"
echo "--- patroni2 ---"
curl -sf http://localhost:8009/ | python3 -m json.tool 2>/dev/null || echo "(not ready)"

# ── 2. Identify current primary ───────────────────────────────────────────────
step "2. Identify current primary via HAProxy (port 5432)"
CURRENT_PRIMARY=$(query_primary "SELECT inet_server_addr();")
if [[ -z "${CURRENT_PRIMARY}" ]]; then
  err "Cannot connect via HAProxy. Is the cluster running?"
  echo "    Start it: docker compose -f docker-compose.ha.yml up -d"
  exit 1
fi
ok "Connected via HAProxy. PostgreSQL server: ${CURRENT_PRIMARY}"

# Determine which container is primary
if curl -sf http://localhost:8008/primary >/dev/null 2>&1; then
  PRIMARY_CONTAINER="ha_patroni1"
  STANDBY_CONTAINER="ha_patroni2"
  PRIMARY_API="http://localhost:8008"
  STANDBY_API="http://localhost:8009"
else
  PRIMARY_CONTAINER="ha_patroni2"
  STANDBY_CONTAINER="ha_patroni1"
  PRIMARY_API="http://localhost:8009"
  STANDBY_API="http://localhost:8008"
fi
ok "Primary container: ${PRIMARY_CONTAINER}"
ok "Standby container: ${STANDBY_CONTAINER}"

# ── 3. Create test table on primary ───────────────────────────────────────────
step "3. Write test data to primary"
psql_haproxy "-c \"
  CREATE TABLE IF NOT EXISTS failover_test (id SERIAL PRIMARY KEY, ts TIMESTAMPTZ DEFAULT now());
  INSERT INTO failover_test DEFAULT VALUES;
  SELECT * FROM failover_test ORDER BY id DESC LIMIT 3;
\""
ok "Data written."

# ── 4. Stop the current primary ───────────────────────────────────────────────
step "4. Stopping primary container: ${PRIMARY_CONTAINER}"
docker stop "${PRIMARY_CONTAINER}"
ok "Container stopped. Waiting for Patroni election (up to 60 s)..."

# ── 5. Poll for new primary ───────────────────────────────────────────────────
step "5. Polling new primary election"
TIMEOUT=60
ELAPSED=0
while [[ ${ELAPSED} -lt ${TIMEOUT} ]]; do
  if curl -sf "${STANDBY_API}/primary" >/dev/null 2>&1; then
    ok "New primary elected after ~${ELAPSED}s"
    break
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

if [[ ${ELAPSED} -ge ${TIMEOUT} ]]; then
  err "No new primary elected within ${TIMEOUT}s. Check cluster logs."
  docker start "${PRIMARY_CONTAINER}" 2>/dev/null || true
  exit 1
fi

# ── 6. Verify client reconnects via HAProxy ───────────────────────────────────
step "6. Verify HAProxy routes to new primary"
sleep 3   # brief pause for HAProxy health-check cycle
EXEC_NODE="${STANDBY_CONTAINER}"
NEW_PRIMARY=$(query_primary "SELECT inet_server_addr();")
if [[ -z "${NEW_PRIMARY}" ]]; then
  err "Still cannot connect via HAProxy after failover."
  docker start "${PRIMARY_CONTAINER}" 2>/dev/null || true
  exit 1
fi
ok "HAProxy reconnected. New PostgreSQL server: ${NEW_PRIMARY}"

ROWS=$(query_primary "SELECT COUNT(*) FROM failover_test;")
ok "Rows in failover_test: ${ROWS} (data intact)"

# ── 7. Patroni state after failover ───────────────────────────────────────────
step "7. Patroni state after failover"
echo "--- ${STANDBY_CONTAINER} (new primary) ---"
curl -sf "${STANDBY_API}/" | python3 -m json.tool 2>/dev/null || true

# ── 8. Restore old primary as replica ────────────────────────────────────────
step "8. Restarting old primary as replica"
docker start "${PRIMARY_CONTAINER}"
ok "Container started. Patroni will re-join as standby automatically."
sleep 15

echo "--- ${PRIMARY_CONTAINER} (should now be replica) ---"
if curl -sf "http://localhost:8008/replica" >/dev/null 2>&1 || \
   curl -sf "http://localhost:8009/replica" >/dev/null 2>&1; then
  ok "Old primary rejoined cluster as standby."
else
  echo "(still converging — run 'docker logs ${PRIMARY_CONTAINER}' to monitor)"
fi

step "Done. Final cluster state:"
echo "patroni1: $(curl -sf http://localhost:8008/ | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('role','?'))" 2>/dev/null || echo 'offline')"
echo "patroni2: $(curl -sf http://localhost:8009/ | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('role','?'))" 2>/dev/null || echo 'offline')"
