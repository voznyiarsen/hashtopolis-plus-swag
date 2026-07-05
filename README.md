# Hashtopolis + SWAG (ARM64)

Link to the original project: https://github.com/hashtopolis

## Quick Start

```bash
# 1. Configure environment
cp env.example .env
vim .env

# 2. Run full setup (initializes SWAG, builds images)
make setup

# 3. Start all services
docker compose up -d
```

## Manual Steps

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/) and `docker compose`
- An ARM64 system (e.g., Raspberry Pi)

### Environment

Edit `.env` with your own values. At minimum, change:
- `MYSQL_ROOT_PASS`
- `MYSQL_PASSWORD`
- `HASHTOPOLIS_ADMIN_PASSWORD`

For DNS verification, configure `DNSPLUGIN` and `URL` in `docker-compose.yml`, then add your DNS API keys to `./swag/config/dns-conf/`.

### Commands

| Command            | Description                                |
|--------------------|--------------------------------------------|
| `make check`       | Verify prerequisites                       |
| `make swag-init`   | Initialize SWAG config files               |
| `make build`       | Build Docker images (parallel)             |
| `make up`          | Start all services                         |
| `make down`        | Stop all services                          |
| `make logs`        | Tail logs from all services                |
| `make update`      | Pull upstream, rebuild, restart            |
| `make clean`       | Remove cloned upstream repos               |
| `./build-images.sh --help` | Full build script options           |

## Notes

- If you use DNS verification, add your DNS API keys to the `.ini` file of your provider inside `./swag/config/dns-conf/`
- The `env.example` includes `HASHTOPOLIS_DB_HOST=db` — this is overridden to `hashtopolis-db` in `docker-compose.yml`
