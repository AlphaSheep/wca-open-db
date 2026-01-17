#!/bin/bash
set -eo pipefail

# Prechecks: required environment variables must be set
: "${MARIADB_ROOT_PASSWORD:?MARIADB_ROOT_PASSWORD is required}"
: "${MARIADB_DATABASE:?MARIADB_DATABASE is required}"

echo "Cleaning up old temporary files..."
find /tmp -maxdepth 1 -type d -name "wca_db_*" -exec rm -rf {} +

TMP_DIR=$(mktemp -d "/tmp/wca_db_$(date +%Y%m%d_%H%M%S)_XXXXXX")
LOCK_FILE="/var/lock/wca_import.lock"
LOCK_FD=9

# Cleanup temporary directory and lock on exit
trap 'rc=$?; [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR" >/dev/null 2>&1 || true; \
      if [ -n "$LOCK_FD" ]; then flock -u "$LOCK_FD" >/dev/null 2>&1 || true; fi; \
      [ -n "$LOCK_FILE" ] && rm -f "$LOCK_FILE" >/dev/null 2>&1 || true; \
      exit $rc' EXIT

# Acquire non-blocking lock to prevent concurrent imports
exec $LOCK_FD>"$LOCK_FILE"
if ! flock -n "$LOCK_FD"; then
    echo "Another import is already running; exiting."
    exit 0
fi

# Verify database connectivity before proceeding
if ! mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
    echo "Database is not reachable with the provided credentials; aborting."
    exit 1
fi

WCA_PUBLIC_EXPORT_URL=${WCA_PUBLIC_EXPORT_URL:-"https://www.worldcubeassociation.org/export/results/v2/sql"}
WCA_DEVELOPER_EXPORT_URL=${WCA_DEVELOPER_EXPORT_URL:-"https://assets.worldcubeassociation.org/export/developer/wca-developer-database-dump.zip"}

if [ "${USE_WCA_DEVELOPER_EXPORT}" = "true" ]; then
    echo "Using WCA developer export."
    WCA_EXPORT_URL="$WCA_DEVELOPER_EXPORT_URL"
    RESULTS_FILE="wca-developer-database-dump.sql"
else
    echo "Using WCA public export."
    WCA_EXPORT_URL="$WCA_PUBLIC_EXPORT_URL"
    RESULTS_FILE="WCA_export.sql"
fi

wget -O "$TMP_DIR/WCA_export.sql.zip" "$WCA_EXPORT_URL"
unzip -o "$TMP_DIR/WCA_export.sql.zip" -d "$TMP_DIR"

echo "Importing WCA database from $RESULTS_FILE into $MARIADB_DATABASE"
if [ "${USE_WCA_DEVELOPER_EXPORT}" = "true" ]; then
    echo "Note: The developer export may take an hour or more to import."
fi

mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`;"
mariadb -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" < "$TMP_DIR/$RESULTS_FILE"

if [ "${USE_WCA_DEVELOPER_EXPORT}" = "true" ]; then
    echo "Done loading developer export"
else
    # Copy out metadata.json
    mkdir -p "/wca-metadata"
    mv "$TMP_DIR/metadata.json" "/wca-metadata/metadata.json"
    echo "Done loading public export"
    echo "Metadata file copied to /wca-metadata/metadata.json"
fi

if [ "${BUILD_ATTEMPTS_INDEX}" = "true" ]; then
    echo "Indexing attempts table..."
    mariadb -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" -e \
        "ALTER TABLE results ADD INDEX idx_results_event_id (event_id), ALGORITHM=INPLACE, LOCK=NONE;" \
        || echo "idx_results_event_id already exists or could not be created; continuing."
    mariadb -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" -e \
        "ALTER TABLE result_attempts ADD INDEX idx_attempts_result_id (result_id), ALGORITHM=INPLACE, LOCK=NONE;" \
        || echo "idx_attempts_result_id already exists or could not be created; continuing."
    echo "Indexing complete."
fi