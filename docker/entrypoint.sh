#!/bin/bash
set -e

# Start cron in the background
service cron start

# Delegate to the official MariaDB entrypoint, passing all arguments
exec /usr/local/bin/docker-entrypoint.sh "$@"
