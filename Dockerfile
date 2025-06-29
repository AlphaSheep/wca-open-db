# Start from the official MariaDB image
FROM mariadb:latest

# Install required tools
RUN apt-get update && apt-get install -y wget unzip cron && rm -rf /var/lib/apt/lists/*

# Copy import script and cronjob
COPY docker/import-wca-db.sh /docker/import-wca-db.sh
COPY docker/cronjob /etc/cron.d/import-wca-db

# Copy entrypoint wrapper script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Make script executable
RUN chmod +x /docker/import-wca-db.sh

# Give proper permissions to cronjob
RUN chmod 0644 /etc/cron.d/import-wca-db

# Apply cron job
RUN crontab /etc/cron.d/import-wca-db

# Create log file
RUN touch /var/log/cron.log

# Expose MariaDB port
EXPOSE 3306

# Declare the data directory as a volume for persistence
VOLUME /var/lib/mysql

# Use custom entrypoint to start cron and delegate to MariaDB entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["mariadbd"]
