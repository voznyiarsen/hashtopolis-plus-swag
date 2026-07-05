#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_prerequisites() {
  if ! command -v docker &>/dev/null; then
    log_error "Docker is not installed."
    exit 1
  fi
  if ! docker info &>/dev/null; then
    log_error "Docker daemon is not running or current user lacks permissions."
    exit 1
  fi
}

setup_env() {
  if [[ -f ".env" ]]; then
    log_info ".env file already exists, skipping"
  else
    if [[ ! -f "env.example" ]]; then
      log_error "env.example not found"
      exit 1
    fi
    cp env.example .env
    log_warn "Created .env from env.example -- please edit it with your settings:"
    log_warn "  vim .env"
    log_warn "  At minimum, set: MYSQL_ROOT_PASS, MYSQL_PASSWORD, HASHTOPOLIS_ADMIN_PASSWORD"
    echo
    read -rp "Press Enter after you have edited .env, or Ctrl-C to abort..."
  fi
}

main() {
  echo
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Hashtopolis Setup${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo

  check_prerequisites
  setup_env

  echo
  log_info "Building Docker images..."
  ./build-images.sh

  echo
  log_ok "Setup complete!"
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Start Hashtopolis:${NC}"
  echo -e "${GREEN}    docker compose up -d${NC}"
  echo -e "${GREEN}========================================${NC}"
}

main "$@"
