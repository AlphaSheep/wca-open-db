# Unofficial WCA MariaDB Docker Image

A hands-off MariaDB server with the latest World Cube Association (WCA) database, updated daily.

## Features
- Based on the official MariaDB image
- Downloads and imports the latest WCA database dump daily (via cron)
- Ready for ad hoc queries or as a backend for projects needing WCA data

## Usage
1. **Create a `.env` file** with the following contents (replace values as needed):

  ```
  MYSQL_ROOT_PASSWORD=yourpassword
  MYSQL_DATABASE=wca
  ```

2. **Build the image:**
   ```bash
   docker build -t wca-mariadb:latest .
   ```
3. **Run the container:**
   ```bash
   docker run -d --name wca-mariadb --env-file .env -p 3306:3306 wca-mariadb:latest
   ```

## Environment Variables
- `MYSQL_ROOT_PASSWORD`: MariaDB root password
- `MYSQL_DATABASE`: Database to import WCA data into

## Notes
- The database is updated daily at 01:00 UTC by default.
- You can change the schedule by editing `docker/cronjob`.
- Logs are available in `/var/log/cron.log` inside the container.

## Publishing
To publish to GHCR or Docker Hub, tag and push as usual.

---


