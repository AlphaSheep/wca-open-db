#!/bin/bash
# Common test helper functions

# Wait for MariaDB to be ready in a container
# Usage: wait_for_mariadb CONTAINER_NAME [PASSWORD] [TIMEOUT_SECONDS]
wait_for_mariadb() {
  local container_name="$1"
  local password="${2:-pass}"
  local timeout="${3:-120}"

  echo "Waiting for MariaDB to be ready..."
  for i in $(seq 1 "$timeout"); do
    if docker exec "$container_name" mariadb -u root -p"$password" -e "SELECT 1" >/dev/null 2>&1; then
      echo "MariaDB is ready"
      return 0
    fi
    sleep 1
    if [ "$i" -eq "$timeout" ]; then
      echo "ERROR: MariaDB did not become ready after ${timeout}s"
      docker logs "$container_name"
      return 1
    fi
  done
}

# Start a test container with common settings
# Usage: start_test_container CONTAINER_NAME IMAGE [EXTRA_ENV_VARS]
start_test_container() {
  local container_name="$1"
  local image="$2"
  shift 2

  docker run -d --name "$container_name" \
    --network host \
    -e MARIADB_ROOT_PASSWORD=pass \
    -e MARIADB_DATABASE=wca \
    "$@" \
    "$image"
}

# Setup cleanup trap for a container
# Usage: setup_cleanup CONTAINER_NAME
setup_cleanup() {
  local container_name="$1"
  trap "docker rm -f '$container_name' >/dev/null 2>&1 || true" EXIT
}
