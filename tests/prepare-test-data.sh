#!/bin/bash
set -euo pipefail

# Create a minimal WCA export for testing
OUTPUT_DIR="${1:-/tmp}"

cat > "$OUTPUT_DIR/WCA_export.sql" <<'SQL'
DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (id INT PRIMARY KEY, name VARCHAR(50));
INSERT INTO test_table VALUES (1, 'ok');

DROP TABLE IF EXISTS results;
CREATE TABLE results (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  event_id VARCHAR(6) NOT NULL
);

DROP TABLE IF EXISTS result_attempts;
CREATE TABLE result_attempts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  result_id BIGINT NOT NULL
);
SQL

echo '{}' > "$OUTPUT_DIR/metadata.json"
(cd "$OUTPUT_DIR" && zip -q WCA_export.sql.zip WCA_export.sql metadata.json)

echo "Test data prepared at $OUTPUT_DIR/WCA_export.sql.zip"

# Start a simple HTTP server to serve the test file
echo "Starting HTTP server on port 8888..."
cd "$OUTPUT_DIR"
python3 -m http.server 8888 >/dev/null 2>&1 &
HTTP_SERVER_PID=$!
echo "$HTTP_SERVER_PID" > "$OUTPUT_DIR/http_server.pid"

# Wait a moment for the server to start
sleep 1

echo "HTTP server started (PID: $HTTP_SERVER_PID)"
echo "Test export available at: http://localhost:8888/WCA_export.sql.zip"
