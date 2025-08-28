#!/bin/bash
set -e

echo "Cleaning up old temporary files..."
find /tmp -maxdepth 1 -type d -name "wca_db_*" -exec rm -rf {} +

TMP_DIR=$(mktemp -d "/tmp/wca_db_$(date +%Y%m%d_%H%M%S)_XXXXXX")
trap 'rc=$?; rm -rf "$TMP_DIR" >/dev/null 2>&1 || true; exit $rc' EXIT

WCA_PUBLIC_EXPORT_URL="https://www.worldcubeassociation.org/export/results/WCA_export.sql"
WCA_DEVELOPER_EXPORT_URL="https://assets.worldcubeassociation.org/export/developer/wca-developer-database-dump.zip"

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

rm -rf "$TMP_DIR"
