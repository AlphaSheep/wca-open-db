#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Run smoke import test
IMAGE="${1:-wca-open-db:test}"
CONTAINER_NAME="wca-smoke-test-$$"

setup_cleanup "$CONTAINER_NAME"

echo "Running smoke import test with image: $IMAGE"

start_test_container "$CONTAINER_NAME" "$IMAGE" \
  -e WCA_PUBLIC_EXPORT_URL="http://localhost:8888/WCA_export.sql.zip"

wait_for_mariadb "$CONTAINER_NAME"

# Run import
docker exec "$CONTAINER_NAME" bash -c "WCA_PUBLIC_EXPORT_URL=http://localhost:8888/WCA_export.sql.zip /docker/import-wca-db.sh"

# Verify data
docker exec "$CONTAINER_NAME" mariadb -u root -ppass -e "SELECT name FROM test_table WHERE id=1" wca

echo "✓ Smoke test passed"
