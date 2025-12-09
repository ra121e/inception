# USER_DOC

## Overview

This project deploys a small web stack using Docker and Docker Compose. As an end user or administrator, you get:

- A WordPress website served over HTTPS on port `443`.
- A MariaDB database storing the WordPress data.
- NGINX as a reverse proxy and single entrypoint to the stack.

All services run as containers and share data using bind-mounted volumes under `/home/LOGIN/data` on the host (replace `LOGIN` with the actual 42 login, e.g. `athonda`).

## Services Provided

- **NGINX**
  - Terminates TLS (HTTPS).
  - Forwards PHP requests to the WordPress container (PHP-FPM).
  - Listens only on port `443`.

- **WordPress + PHP-FPM**
  - Runs the WordPress CMS application.
  - Handles PHP execution via PHP-FPM on port `9000` (internal only).

- **MariaDB**
  - Stores the WordPress database (posts, users, settings, etc.).
  - Listens on port `3306` inside the Docker network (not published to the host).

## Starting and Stopping the Project

All commands are executed from the project root directory.

### Start the stack

```bash
make
# or
make up
```

This will:

- Create the host data directories under `/home/LOGIN/data/mariadb` and `/home/LOGIN/data/wordpress`.
- Build the Docker images.
- Start the containers in the background.

### Stop the stack

```bash
make down
```

Stops and removes the running containers defined in `srcs/docker-compose.yml`.

### Clean up containers, images, volumes, networks

```bash
make clean
```

- Stops the stack.
- Removes containers, images, volumes, and networks created by Docker.

### Full reset (including host data)

```bash
make fclean
```

- Does everything `make clean` does.
- Additionally removes the host data directories under `/home/LOGIN/data`.

After `make fclean`, all WordPress data and database contents are lost.

## Accessing the Website and Admin Panel

### Website URL

The public website is served over HTTPS by NGINX.

- Domain: value of `DOMAIN_NAME` defined in `srcs/.env`.
- Example: `https://athonda.42.fr`

Make sure that your system resolves this domain to the virtual machine's IP address (e.g., by using `/etc/hosts` during development).

### WordPress Admin Panel

- URL: `https://<DOMAIN_NAME>/wp-admin`
  - Example: `https://athonda.42.fr/wp-admin`

### Credentials

- During the first startup, the WordPress setup script creates:
  - An **administrator user** (login from `WP_ADMIN_USER` in `.env`).
  - A **regular user** (login from `WP_USER` in `.env`).
- Passwords are read from Docker secrets mounted inside the containers and are **not stored** in the Git repository.

The administrator username is intentionally chosen so that it does not contain `admin` or `administrator`, in order to comply with the subject requirements.

## Locating and Managing Credentials

### Where credentials live

- **Environment configuration**: `srcs/.env`
  - Contains non-sensitive values such as:
    - `LOGIN`
    - `DOMAIN_NAME`
    - `MYSQL_DATABASE`, `MYSQL_USER`
    - WordPress usernames and emails
- **Secrets (passwords and sensitive data)**: `secrets/`
  - `db_root_password.txt`: MariaDB root password
  - `db_password.txt`: WordPress database user password
  - `credentials.txt`: WordPress user passwords (admin and regular user)

These files are **not** committed to Git and are referenced as Docker secrets in `srcs/docker-compose.yml`.

### How to change credentials

1. Stop the stack:
   ```bash
   make down
   ```
2. Edit the appropriate file in `secrets/` (e.g. change passwords in `credentials.txt`).
3. If you change usernames or emails, also update `srcs/.env` (e.g. `WP_ADMIN_USER`, `WP_USER`, etc.).
4. Start the stack again:
   ```bash
   make up
   ```

For existing WordPress installations, changing credentials via the WordPress admin panel is also possible.

## Checking That Services Are Running

### With Docker commands

From the project root (or any directory):

```bash
docker ps
```

You should see at least the following containers:

- `nginx`
- `wordpress`
- `mariadb`

Their status should be `Up` (running).

### With Makefile helper

To follow the logs of all services:

```bash
make logs
```

This tails the logs for all services defined in `docker-compose.yml` and is useful to verify that:

- MariaDB has initialized and is accepting connections.
- WordPress has been installed and configured successfully.
- NGINX is listening on port `443` and serving requests.

### By accessing the website

Open a browser and navigate to:

- `https://<DOMAIN_NAME>`

If you see the WordPress site, the stack is running correctly. To check the admin:

- `https://<DOMAIN_NAME>/wp-admin`

Log in with the administrator credentials provided by the secrets and `.env` configuration.

## Troubleshooting (User Level)

- If the site is not reachable:
  - Check that the VM is running and accessible.
  - Verify `/etc/hosts` or DNS resolves `<DOMAIN_NAME>` to the VM's IP.
  - Run `make logs` to look for obvious errors.
- If you changed credentials and cannot log in:
  - Confirm that secrets files and `.env` values are consistent.
  - Consider resetting passwords directly via the WordPress admin UI or the database (developer assistance may be needed).
