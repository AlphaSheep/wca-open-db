#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Test index creation and idempotency
IMAGE="${1:-wca-open-db:test}"
CONTAINER_NAME="wca-index-test-$$"

setup_cleanup "$CONTAINER_NAME"

echo "Running index creation and idempotency test with image: $IMAGE"

start_test_container "$CONTAINER_NAME" "$IMAGE"

wait_for_mariadb "$CONTAINER_NAME"

# First import: indexes should be created
echo "Running first import with BUILD_ATTEMPTS_INDEX=true..."
docker exec "$CONTAINER_NAME" bash -c "WCA_PUBLIC_EXPORT_URL=http://localhost:8888/WCA_export.sql.zip BUILD_ATTEMPTS_INDEX=true /docker/import-wca-db.sh"

echo "Verifying indexes were created..."
docker exec "$CONTAINER_NAME" bash -c "test \$(mariadb -N -B -u root -ppass -e \"SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='wca' AND table_name='results' AND index_name='idx_results_event_id';\") -ge 1"
docker exec "$CONTAINER_NAME" bash -c "test \$(mariadb -N -B -u root -ppass -e \"SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='wca' AND table_name='result_attempts' AND index_name='idx_attempts_result_id';\") -ge 1"

# Second import: indexes already exist; should not fail and remain present
echo "Running second import (idempotency check)..."
docker exec "$CONTAINER_NAME" bash -c "WCA_PUBLIC_EXPORT_URL=http://localhost:8888/WCA_export.sql.zip BUILD_ATTEMPTS_INDEX=true /docker/import-wca-db.sh"

echo "Verifying indexes still exist..."
docker exec "$CONTAINER_NAME" bash -c "test \$(mariadb -N -B -u root -ppass -e \"SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='wca' AND table_name='results' AND index_name='idx_results_event_id';\") -ge 1"
docker exec "$CONTAINER_NAME" bash -c "test \$(mariadb -N -B -u root -ppass -e \"SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='wca' AND table_name='result_attempts' AND index_name='idx_attempts_result_id';\") -ge 1"

echo "✓ Index test passed"
