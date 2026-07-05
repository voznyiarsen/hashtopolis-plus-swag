#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $(date '+%H:%M:%S')  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $(date '+%H:%M:%S')  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $(date '+%H:%M:%S')  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S')  $*"; }

CACHE_FLAG=""
NO_CACHE=false
PARALLEL=false

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Build Hashtopolis Docker images from upstream source.

Options:
  --no-cache    Build images without using Docker cache
  --parallel    Build both images at once (default: sequential)
  --help        Show this help message and exit
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-cache) NO_CACHE=true; shift ;;
    --parallel) PARALLEL=true; shift ;;
    --help)     usage ;;
    *) log_error "Unknown option: $1"; usage ;;
  esac
done

$NO_CACHE && CACHE_FLAG="--no-cache"

cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_error "Build failed with exit code $exit_code"
  fi
}
trap cleanup EXIT

check_prerequisites() {
  log_info "Checking prerequisites..."

  if ! command -v docker &>/dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
  fi

  if ! docker info &>/dev/null; then
    log_error "Docker daemon is not running or current user lacks permissions."
    exit 1
  fi

  log_ok "Docker is available"
}

ensure_repo() {
  local repo_url="$1"
  local dir="$2"

  if [[ -d "$dir" ]]; then
    if [[ -d "$dir/.git" ]]; then
      log_info "Updating $dir from upstream..."
      if ! (cd "$dir" && git pull --ff-only 2>/dev/null); then
        log_warn "Fast-forward pull failed for $dir, re-cloning..."
        rm -rf "$dir"
        git_clone "$repo_url" "$dir"
      else
        log_ok "$dir is up to date"
      fi
    else
      log_warn "$dir exists but is not a git repo, re-cloning..."
      rm -rf "$dir"
      git_clone "$repo_url" "$dir"
    fi
  else
    git_clone "$repo_url" "$dir"
  fi
}

git_clone() {
  local repo_url="$1"
  local dir="$2"
  log_info "Cloning $repo_url ..."
  local max_attempts=3
  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if git clone --depth 1 "$repo_url" "$dir" 2>/dev/null; then
      log_ok "Cloned $dir"
      return 0
    fi
    log_warn "Clone attempt $attempt/$max_attempts failed, retrying..."
    attempt=$((attempt + 1))
    sleep 2
  done
  log_error "Failed to clone $repo_url after $max_attempts attempts"
  exit 1
}

build_image() {
  local name="$1"
  local tag="$2"
  local target="$3"
  local context="$4"

  log_info "Building $name ($tag)..."
  if docker build $CACHE_FLAG -t "$tag" --target "$target" "$context"; then
    log_ok "$name built successfully"
    return 0
  else
    log_error "$name build failed"
    return 1
  fi
}

main() {
  echo
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Hashtopolis Image Builder${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo

  check_prerequisites

  ensure_repo "https://github.com/hashtopolis/web-ui.git" "web-ui"
  ensure_repo "https://github.com/hashtopolis/server.git" "server"

  echo
  log_info "Starting Docker builds..."

  local failed=false

  if $PARALLEL; then
    build_image "frontend" "hashtopolis/frontend:latest" "hashtopolis-web-ui-prod" "web-ui" &
    pid_frontend=$!
    build_image "backend"  "hashtopolis/backend:latest"  "hashtopolis-server-prod"  "server" &
    pid_backend=$!

    wait $pid_frontend || failed=true
    wait $pid_backend  || failed=true
  else
    build_image "frontend" "hashtopolis/frontend:latest" "hashtopolis-web-ui-prod" "web-ui" || failed=true
    build_image "backend"  "hashtopolis/backend:latest"  "hashtopolis-server-prod"  "server" || failed=true
  fi

  echo
  if $failed; then
    log_error "One or more builds failed"
    exit 1
  fi

  log_ok "All images built successfully"
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Build complete! Run:${NC}"
  echo -e "${GREEN}    docker compose up -d${NC}"
  echo -e "${GREEN}========================================${NC}"
}

main "$@"
