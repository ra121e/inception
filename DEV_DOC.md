# DEV_DOC

## Purpose

This document describes how to set up, build, and manage the Inception project from a developer perspective. It focuses on:

- Environment and prerequisites
- Configuration files and secrets
- Build and runtime flow
- Managing containers, networks, and volumes
- Where and how data is persisted

## 1. Environment Setup

### 1.1. Prerequisites

- A Linux virtual machine (as required by the subject).
- Installed tools:
  - Docker Engine
  - Docker Compose or the `docker compose` plugin
- A user account matching the 42 login used in the project.

Verify Docker and Compose:

```bash
docker --version
docker compose version
```

### 1.2. Repository Layout

From the project root:

- `Makefile` — entry point to build and run the stack.
- `secrets/` — local passwords and credentials (ignored by Git).
  - `credentials.txt`
  - `db_password.txt`
  - `db_root_password.txt`
- `srcs/`
  - `.env` — environment variables (non-sensitive).
  - `docker-compose.yml` — service, network, and volume definitions.
  - `requirements/`
    - `mariadb/`
      - `Dockerfile`
      - `conf/50-server.cnf`
      - `tools/setup_db.sh`
    - `nginx/`
      - `Dockerfile`
      - `conf/nginx.conf`
      - `tools/init_ssl.sh`
    - `wordpress/`
      - `Dockerfile`
      - `conf/www.conf`
      - `tools/setup_wordpress.sh`

## 2. Configuration and Secrets

### 2.1. `.env` file

`srcs/.env` holds non-sensitive configuration that is injected into containers via `env_file`:

- General:
  - `LOGIN` — 42 login, used for host data paths.
  - `DOMAIN_NAME` — FQDN for the NGINX virtual host (e.g. `athonda.42.fr`).
- MariaDB:
  - `MYSQL_DATABASE`, `MYSQL_USER`
- WordPress:
  - `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`
  - `WP_USER`, `WP_USER_EMAIL`
- Internal DB connection:
  - `DB_HOST`, `DB_PORT`

Passwords are **not** stored in `.env`.

### 2.2. Secrets folder

`secrets/` contains sensitive data read by containers via Docker secrets:

- `db_root_password.txt` — MariaDB root password.
- `db_password.txt` — MariaDB user password used by WordPress.
- `credentials.txt` — WordPress user passwords (admin and regular user), one per line.

`srcs/docker-compose.yml` maps these files to Docker secrets that appear as files under `/run/secrets/` inside containers.

## 3. Build and Launch Flow

### 3.1. Makefile targets

From the repository root:

```bash
make        # create host data directories and start the stack
make up     # start/rebuild the stack in detached mode
make down   # stop the stack and remove containers (images left)
make start  # start containers
make stop   # stop containers
make clean  # down
make fclean # clean + remove remove containers/images/volumes/networks
make re     # clean and rebuild the stack
```

Underlying commands use `docker compose -f srcs/docker-compose.yml ...`.

### 3.2. Docker Compose definitions

`srcs/docker-compose.yml` defines:

- **Services**:
  - `mariadb` — built from `requirements/mariadb`, exposes port `3306` only inside the Docker network.
  - `wordpress` — built from `requirements/wordpress`, runs PHP-FPM on port `9000` (internal only).
  - `nginx` — built from `requirements/nginx`, exposes port `443` to the host.
- **Network**:
  - `inception_network` — custom bridge network for container-to-container communication.
- **Volumes** (bind-mounted local volumes):
  - `mariadb_data` → `/home/${LOGIN}/data/mariadb` ↔ `/var/lib/mysql`
  - `wordpress_data` → `/home/${LOGIN}/data/wordpress` ↔ `/var/www/html/wordpress`
- **Secrets**:
  - `db_root_password`, `db_password`, `credentials` mapped from the `../secrets` directory.

## 4. Service Internals

### 4.1. MariaDB service

- **Image**: built from `srcs/requirements/mariadb/Dockerfile` (Alpine-based).
- **Configuration**:
  - `conf/50-server.cnf` sets bind-address, port, charset, and socket.
- **Init script**: `tools/setup_db.sh`
  - Creates `/run/mysqld` and initializes the data directory if needed.
  - Reads passwords from `/run/secrets/db_root_password` and `/run/secrets/db_password`.
  - Runs `mysql_install_db` on first startup.
  - Configures root user, removes anonymous users and test DB.
  - Creates the WordPress database and grant user defined by `MYSQL_DATABASE` and `MYSQL_USER`.
  - Starts `mysqld` in the foreground so that PID 1 is the database server.

### 4.2. WordPress service

- **Image**: built from `srcs/requirements/wordpress/Dockerfile` (Alpine-based, PHP-FPM).
- **Configuration**:
  - `conf/www.conf` configures PHP-FPM to listen on `0.0.0.0:9000`.
  - `php.ini` is adjusted for session storage and memory limits.
- **Init script**: `tools/setup_wordpress.sh`
  - Reads DB connection data from `.env` and DB password from `/run/secrets/db_password`.
  - Reads WordPress user passwords from `/run/secrets/credentials`.
  - Uses `wp-cli` to:
    - Download WordPress.
    - Generate `wp-config.php`.
    - Run `wp core install` with admin user and password.
    - Create an additional regular user.
    - Configure site URLs and enforce HTTPS.
  - Finally `exec`s PHP-FPM in the foreground (`php-fpm81 -F`).

### 4.3. NGINX service

- **Image**: built from `srcs/requirements/nginx/Dockerfile` (Alpine-based).
- **Configuration**:
  - `conf/nginx.conf` defines a server listening on `443` with `ssl_protocols TLSv1.2 TLSv1.3`.
  - `server_name` is set from `DOMAIN_NAME`.
  - Root is the WordPress directory from the shared volume.
  - PHP requests are forwarded to `wordpress:9000` via FastCGI.
- **TLS setup**:
  - `tools/init_ssl.sh` generates a self-signed certificate under `/etc/nginx/ssl` using the CN from `DOMAIN_NAME`.
  - The script runs at build time and can be extended or replaced with a runtime solution if needed.

## 5. Data Persistence

### 5.1. Volumes and Bind Mounts

`docker-compose.yml` defines named volumes with `driver_opts` to create bind mounts:

- `mariadb_data` → `/home/${LOGIN}/data/mariadb` ↔ `/var/lib/mysql`
- `wordpress_data` → `/home/${LOGIN}/data/wordpress` ↔ `/var/www/html/wordpress`

This ensures:

- Database data persists across container rebuilds.
- WordPress files (core, themes, plugins, uploads) persist across container rebuilds.

### 5.2. Inspecting Data

On the host, you can inspect data directly:

```bash
ls -R /home/$USER/data/mariadb
ls -R /home/$USER/data/wordpress
```

Use `docker exec` for container-level introspection:

```bash
docker exec -it mariadb sh
docker exec -it wordpress sh
docker exec -it nginx sh
```

## 6. Common Developer Tasks

### 6.1. Rebuilding after changes

After modifying Dockerfiles or configuration under `srcs/requirements`, rebuild and restart:

```bash
make build
make down
make up
```

Or perform a full clean rebuild:

```bash
make re
```

### 6.2. Checking container logs

```bash
make logs
```

Look for:

- MariaDB startup or authentication errors.
- WordPress installation or database connection errors.
- NGINX configuration or TLS issues.

### 6.3. Adding or Modifying Services (Bonus)

For any new service you add (bonus part):

1. Create a new directory under `srcs/requirements/<service_name>/`.
2. Add a `Dockerfile`, `conf/` and/or `tools/` as needed.
3. Extend `srcs/docker-compose.yml` with the new service, network attachments, and volumes.
4. If the service needs credentials, add new secrets under `secrets/` and reference them via Docker secrets.

## 7. Notes and Caveats

- Do not hard-code passwords in Dockerfiles, source code, or committed files.
- Avoid using `latest` tags for base images; prefer explicit, stable versions.
- Do not use `network: host` or deprecated `links` in Docker Compose.
- Ensure the admin WordPress username **does not** contain `admin` or `administrator` substrings.

This document should give developers enough context to understand, modify, and extend the project while staying within the subject’s requirements.
