#!/bin/bash
set -e
TMP_DIR=$(mktemp -d "/tmp/wca_db_$(date +%Y%m%d_%H%M%S)")

WCA_EXPORT_URL="https://www.worldcubeassociation.org/export/results/WCA_export.sql"

wget -O "$TMP_DIR/WCA_export.sql.zip" "$WCA_EXPORT_URL"
unzip -o "$TMP_DIR/WCA_export.sql.zip" -d "$TMP_DIR"

mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < "$TMP_DIR/WCA_export.sql"

rm -rf "$TMP_DIR"
