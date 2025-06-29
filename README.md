
# Unofficial WCA Open DB Docker Image


A hands-off database server with the latest World Cube Association (WCA) public database export, updated daily.

## Features
- Based on the official MariaDB image
- Downloads and imports the latest WCA public database export daily (via cron)
- Ready for ad hoc queries or as a backend for projects needing WCA data

## Usage
1. **Create a `.env` file** with the following contents (replace values as needed):

  ```
  MYSQL_ROOT_PASSWORD=yourpassword
  MYSQL_DATABASE=wca
  ```


2. **Build the image:**
   ```bash
   docker build -t wca-open-db:latest .
   ```
3. **Run the container with a persistent volume:**
   ```bash
   docker run -d \
     --name wca-open-db \
     --env-file .env \
     -p 3306:3306 \
     -v wca-open-db-data:/var/lib/mysql \
     wca-open-db:latest
   ```

   This will create (or reuse) a Docker-managed volume named `wca-open-db-data` to persist your database data across restarts and upgrades.


## Sample Docker Compose


You can also use Docker Compose to manage the database container and persistent storage:

```yaml
services:
  wca-open-db:
    image: wca-open-db:latest
    container_name: wca-open-db
    env_file: .env
    ports:
      - "127.0.0.1:3306:3306"
    volumes:
      - wca-open-db-data:/var/lib/mysql

volumes:
  wca-open-db-data:
```

This will ensure your database data is persisted and the container is easy to manage and restart.


## Environment Variables
- `MYSQL_ROOT_PASSWORD`: MariaDB root password
- `MYSQL_DATABASE`: Database to import WCA data into



## Data Persistence

The MariaDB data directory (`/var/lib/mysql`) is declared as a volume in the Dockerfile. You should mount a volume to this path to persist the data when the container stops or is removed.


## Notes
- The database is updated daily at 01:00 UTC by default.
- You can change the schedule by editing `docker/cronjob`.
- Logs are available in `/var/log/cron.log` inside the container.


## Publishing
To publish to GHCR or Docker Hub, tag and push as usual, e.g.:

```bash
docker tag wca-open-db:latest <your-repo>/wca-open-db:latest
docker push <your-repo>/wca-open-db:latest
```

---


