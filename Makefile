.PHONY: help setup check build up down restart logs update clean

.DEFAULT_GOAL := help

help:
	@echo "Hashtopolis Management"
	@echo ""
	@echo "  setup       Configure .env and build images"
	@echo "  check       Verify prerequisites (docker, .env)"
	@echo "  build       Build Docker images (frontend + backend)"
	@echo "  up          Start all services"
	@echo "  down        Stop all services"
	@echo "  restart     Restart all services"
	@echo "  logs        Tail logs from all services"
	@echo "  update      Pull upstream repos, rebuild images, restart services"
	@echo "  clean       Remove cloned upstream repos"
	@echo ""
	@echo "SWAG:"
	@echo "  Copy hashtopolis.subdomain.conf into your existing SWAG's proxy-confs/"

setup: check
	@./setup.sh

check:
	@echo "Checking prerequisites..."
	@command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is not installed"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "ERROR: docker daemon not running or permission denied"; exit 1; }
	@[ -f .env ] || { echo "ERROR: .env file not found. Copy from env.example and edit it"; exit 1; }
	@echo "All prerequisites met."

build:
	@./build-images.sh

up:
	@docker compose up -d

down:
	@docker compose down

restart: down up

logs:
	@docker compose logs -f

update: check
	@./update.sh

clean:
	@rm -rf web-ui server
	@echo "Removed web-ui and server repos."
