*This project has been created as part of the 42 curriculum by athonda.*

# Inception

## Description

This repository contains the mandatory part of the 42 project **Inception**. The goal is to build a small, production‑like web stack entirely with **Docker** and **docker-compose**, without relying on prebuilt application images (except for the base OS images).

The stack consists of the following services:

- **NGINX**: Reverse proxy and TLS termination, exposing only port `443`.
- **WordPress + PHP-FPM**: Application container running WordPress with PHP-FPM, no NGINX inside.
- **MariaDB**: Database container storing the WordPress data.

All configuration files live under `srcs/`, and the stack is orchestrated by `docker-compose.yml` and a `Makefile` at the project root. Persistent data is stored on the host under `/home/LOGIN/data` using bind-mounted Docker volumes.

### Project Design and Docker Usage

The project is fully containerized using custom Dockerfiles for each service:

- Each service has its own `Dockerfile`, configuration in a `conf/` directory, and initialization scripts in a `tools/` directory under `srcs/requirements/`.
- `docker-compose.yml` defines the services, the custom bridge network, and the bind-mounted volumes.
- Secrets and credentials are provided via Docker secrets and a `.env` file, never hard-coded in Dockerfiles.

Key design choices:

- Use of **Alpine Linux** as a lightweight base image for all services.
- Clear separation of concerns: NGINX, PHP-FPM/WordPress, and MariaDB each run in their own container.
- Use of Docker volumes and bind mounts for data persistence and easy inspection from the host.
- Use of Docker secrets for database and WordPress credentials.

### Concept Comparison

#### Virtual Machines vs Docker

- **Virtual Machines**: Run a full guest OS with its own kernel, are heavier in terms of resource usage, and usually require full system provisioning and maintenance.
- **Docker Containers**: Share the host kernel and isolate processes at the OS level. They are lighter, start faster, and are better suited for microservice or multi‑container architectures.
- In this project, a VM is used as the host environment, but the services themselves are isolated as Docker containers.

#### Secrets vs Environment Variables

- **Environment Variables**:
  - Simple way to pass configuration at runtime.
  - Suitable for non‑sensitive values such as domain names or database names.
- **Docker Secrets**:
  - Designed specifically for sensitive data (passwords, API keys, credentials).
  - Mounted as files inside the container and not exposed via `env`.
- In this project, non‑sensitive settings (e.g., `DOMAIN_NAME`, `MYSQL_DATABASE`) are in `.env`, while passwords and credentials are stored in `secrets/` and mounted as Docker secrets.

#### Docker Network vs Host Network

- **Docker Network (bridge)**:
  - Containers communicate via an isolated virtual network managed by Docker.
  - Service discovery by container name, with explicit published ports for external access.
  - Better isolation and more predictable behavior for multi‑container setups.
- **Host Network**:
  - Containers share the host's network namespace.
  - Less isolation and can conflict with host services.
- This project uses a **custom bridge network** (`inception_network`) so that only NGINX exposes port `443` to the host, while internal services remain reachable only within the Docker network.

#### Docker Volumes vs Bind Mounts

- **Docker Volumes**:
  - Managed by Docker under `/var/lib/docker/volumes` by default.
  - Abstract away the host filesystem paths.
- **Bind Mounts**:
  - Map a specific host directory into the container.
  - Make it easy to inspect or back up data directly from the host.
- The project uses **local volumes with bind mounts**:
  - WordPress database: `/home/LOGIN/data/mariadb` → `/var/lib/mysql`
  - WordPress files: `/home/LOGIN/data/wordpress` → `/var/www/html/wordpress`

## Instructions

### Prerequisites

- A working Linux virtual machine (as required by the subject).
- Docker and Docker Compose (or `docker compose` plugin) installed.
- Your login correctly set in `srcs/.env` as `LOGIN` and in the domain name (e.g. `athonda.42.fr`).

### Basic Usage

From the project root:

```bash
make       # create host data directories and start the stack
make up    # start/rebuild the stack in detached mode
make down  # stop the stack
make clean # stop stack and remove containers/images/volumes/networks
make fclean# clean + remove host data directories
make re    # clean and rebuild the stack
```

After `make` or `make up`, the site should be available at:

- `https://<DOMAIN_NAME>` (e.g. `https://athonda.42.fr`)

For more detailed information on running and administering the stack, see `USER_DOC.md`. For development and maintenance details, see `DEV_DOC.md`.

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/
- WordPress documentation: https://wordpress.org/support/article/

### AI Usage

AI tools were used to help draft configuration files, shell scripts, and documentation, and to reason about Docker best practices. All generated content was reviewed, understood, and, where necessary, modified to match the project requirements and personal understanding.
