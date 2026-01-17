#!/bin/bash
set -euo pipefail

# Run all tests locally
IMAGE="${1:-wca-open-db:test}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() {
  # Stop HTTP server if running
  if [ -f /tmp/http_server.pid ]; then
    HTTP_PID=$(cat /tmp/http_server.pid)
    kill "$HTTP_PID" 2>/dev/null || true
    rm -f /tmp/http_server.pid
  fi
}
trap cleanup EXIT

echo "=== Running WCA Open DB Tests ==="
echo "Image: $IMAGE"
echo

# Prepare test data
echo "=== Preparing test data ==="
"$SCRIPT_DIR/prepare-test-data.sh" /tmp
echo

# Run smoke test
echo "=== Running smoke test ==="
"$SCRIPT_DIR/smoke-test.sh" "$IMAGE"
echo

# Run index test
echo "=== Running index test ==="
"$SCRIPT_DIR/index-test.sh" "$IMAGE"
echo

echo "=== All tests passed! ==="
