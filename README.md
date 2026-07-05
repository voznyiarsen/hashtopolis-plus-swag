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

## Nginx Configs

Two config files are provided depending on your setup:

### SWAG

Copy `hashtopolis.subdomain.conf` into your SWAG `proxy-confs/` directory:

```bash
cp hashtopolis.subdomain.conf /path/to/swag/config/nginx/proxy-confs/
```

This config relies on SWAG's built-in `ssl.conf` and `proxy.conf` includes.

### Raw nginx

`hashtopolis.nginx.conf` is a self-contained config for standalone nginx. Edit the `ssl_certificate` paths and `server_name` to match your setup, then symlink it into your nginx `sites-enabled/`:

```bash
cp hashtopolis.nginx.conf /etc/nginx/sites-available/hashtopolis
ln -s /etc/nginx/sites-available/hashtopolis /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

Generate a self-signed certificate or use your own:

```bash
openssl req -x509 -newkey rsa:2048 -keyout nginx.key -out nginx.crt -days 365 -nodes
```

## Notes

- All Hashtopolis containers attach to the `proxy_net` Docker network — make sure your SWAG instance is on the same network.
- The `env.example` includes `HASHTOPOLIS_DB_HOST=db` — this is overridden to `hashtopolis-db` in `docker-compose.yml`.
