# WCA Open DB

An unofficial hands-off database server with the latest World Cube Association (WCA) public database export, updated daily.

This project is not affiliated with the WCA in any way.


## Features

- Runs MariaDB with the latest public WCA database export
- Automatically downloads and imports new data daily (via cron)
- Simple setup for ad hoc SQL queries or as a backend for your projects
- Data can be persisted across restarts using Docker volumes


## Usage

To run the latest published image:

1. **Create a `.env` file** with the following contents (replace values as needed):
    ```
    MYSQL_ROOT_PASSWORD=yourpassword
    MYSQL_DATABASE=wca
    ```

2. **Run the container from GHCR:**
    ```bash
    docker run -d \
      --name wca-open-db \
      --env-file .env \
      -e IMPORT_WCA_DB_ON_STARTUP=true \
      -p 127.0.0.1:3306:3306 \
      -v wca-open-db-data:/var/lib/mysql \
      ghcr.io/alphasheep/wca-open-db:latest
    ```
    This will pull the image from GHCR and create (or reuse) a Docker-managed volume named `wca-open-db-data` to persist your database data across restarts and upgrades.


### Docker Compose

You can also use Docker Compose to manage the database container and persistent storage:

```yaml
services:
  wca-open-db:
    image: ghcr.io/alphasheep/wca-open-db:latest
    container_name: wca-open-db
    env_file: .env
    environment:
      - IMPORT_WCA_DB_ON_STARTUP=false  # Optional: import latest WCA DB on startup
    ports:
      - "127.0.0.1:3306:3306"
    volumes:
      - wca-open-db-data:/var/lib/mysql

volumes:
  wca-open-db-data:
```

This will ensure your database data is persisted and the container is easy to manage and restart. Set `IMPORT_WCA_DB_ON_STARTUP=true` to automatically import the latest WCA database on container startup.


## Build Locally
If you want to build the image yourself:

1. **Create a `.env` file** with the following contents (replace values as needed):
    ```
    MYSQL_ROOT_PASSWORD=yourpassword
    MYSQL_DATABASE=wca
    # Optional: Set to true to import the latest WCA DB on container startup
    # IMPORT_WCA_DB_ON_STARTUP=true
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
      -e IMPORT_WCA_DB_ON_STARTUP=true \
      -p 127.0.0.1:3306:3306 \
      -v wca-open-db-data:/var/lib/mysql \
      wca-open-db:latest
    ```
    This will create (or reuse) a Docker-managed volume named `wca-open-db-data` to persist your database data across restarts and upgrades.


## Environment Variables

- `MYSQL_ROOT_PASSWORD`: MariaDB root password
- `MYSQL_DATABASE`: Database to import WCA data into
- `IMPORT_WCA_DB_ON_STARTUP`: (optional) If set to `true`, downloads and imports the latest WCA database export on container startup.


## Data Persistence

The MariaDB data directory (`/var/lib/mysql`) is declared as a volume in the Dockerfile. You should mount a volume to this path to persist the data when the container stops or is removed.


## Automatic Updates

- The database is updated daily at 01:00 UTC by default using the WCA public export.
- You can change the schedule by editing `docker/cronjob`.
- Logs are available in `/var/log/cron.log` inside the container.


## Manual Update

To manually download and import the latest WCA database export at any time, run the following command:

```bash
docker exec -it wca-open-db /docker/import-wca-db.sh
```

This will execute the import script inside the running container, using the environment variables you provided.


## Publishing

To publish to GHCR or Docker Hub, tag and push as usual, e.g.:

```bash
docker tag wca-open-db:latest <your-repo>/wca-open-db:latest
docker push <your-repo>/wca-open-db:latest
```


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
