#!/bin/bash
set -e

# Set default values for environment variables if not provided
: "${MARIADB_DATABASE:=wca}"
echo "Using database: $MARIADB_DATABASE"


# Start cron in the background
service cron start

# Delegate to the official MariaDB entrypoint, passing all arguments
/usr/local/bin/docker-entrypoint.sh "$@"  &
DB_PID=$!

# Wait for the MariaDB process to start
echo "Waiting for MariaDB to accept connections…"
until mariadb --protocol=TCP -h127.0.0.1 \
              -u root -p"$MARIADB_ROOT_PASSWORD" \
              -e "SELECT 1" &>/dev/null
do
    sleep 1
done

# Optionally import the latest WCA DB on startup if requested
if [ "${IMPORT_WCA_DB_ON_STARTUP}" = "true" ]; then
    echo "IMPORT_WCA_DB_ON_STARTUP is set. Importing latest WCA database..."
    /docker/import-wca-db.sh
fi

# Wait for the MariaDB process to finish
# This is necessary to keep the container running
echo "Database is ready."
wait "$DB_PID"
