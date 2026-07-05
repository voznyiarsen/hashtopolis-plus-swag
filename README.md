# Hashtopolis + SWAG (ARM64)

Drop-in Hashtopolis containers designed to sit behind an existing [SWAG](https://docs.linuxserver.io/general/swag/) instance.

Link to the original project: https://github.com/hashtopolis

## Quick Start

```bash
# 1. Configure environment
cp env.example .env
vim .env

# 2. Build images
make build

# 3. Start all services
docker compose up -d

# 4. Add the SWAG proxy config
cp hashtopolis.subdomain.conf /path/to/swag/config/nginx/proxy-confs/
```

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/) and `docker compose`
- An ARM64 system (e.g., Raspberry Pi)
- An existing SWAG instance on the `proxy_net` Docker network

## Environment

Edit `.env` with your own values. At minimum, change:
- `MYSQL_ROOT_PASS`
- `MYSQL_PASSWORD`
- `HASHTOPOLIS_ADMIN_PASSWORD`

## Commands

| Command            | Description                                |
|--------------------|--------------------------------------------|
| `make check`       | Verify prerequisites                       |
| `make build`       | Build Docker images (parallel)             |
| `make up`          | Start all services                         |
| `make down`        | Stop all services                          |
| `make logs`        | Tail logs from all services                |
| `make update`      | Pull upstream, rebuild only if changed, restart |
| `make clean`       | Remove cloned upstream repos                  |
| `./update.sh`      | Check for updates, rebuild if needed          |
| `./build-images.sh --help` | Full build script options              |

## SWAG Config

Copy `hashtopolis.subdomain.conf` into your existing SWAG's `proxy-confs/` directory:

```bash
cp hashtopolis.subdomain.conf /path/to/swag/config/nginx/proxy-confs/
```

This config proxies `hashtopolis.*` subdomains to the backend container. Adjust `server_name` and `proxy_pass` as needed.

## Notes

- All Hashtopolis containers attach to the `proxy_net` Docker network — make sure your SWAG instance is on the same network.
- The `env.example` includes `HASHTOPOLIS_DB_HOST=db` — this is overridden to `hashtopolis-db` in `docker-compose.yml`.
