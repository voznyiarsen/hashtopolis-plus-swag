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

REPOS=(
  "https://github.com/hashtopolis/web-ui.git:web-ui"
  "https://github.com/hashtopolis/server.git:server"
)

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

get_head() {
  local dir="$1"
  (cd "$dir" && git rev-parse HEAD 2>/dev/null) || echo ""
}

repo_has_changed() {
  local dir="$1"
  local old_hash="$2"
  local new_hash
  new_hash=$(get_head "$dir")
  [[ "$old_hash" != "$new_hash" ]]
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

build_images() {
  log_info "New commits detected, rebuilding images..."
  ./build-images.sh "$@"
  log_ok "Rebuild complete."
}

restart_services() {
  log_info "Restarting services with new images..."
  docker compose up -d --force-recreate
  log_ok "Services restarted."
}

main() {
  echo
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Hashtopolis Update${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo

  check_prerequisites

  local changed=false
  local old_hashes=()
  local i=0

  for entry in "${REPOS[@]}"; do
    local repo_url="${entry%%:*}"
    local dir="${entry##*:}"

    old_hashes[$i]=$(get_head "$dir")
    ensure_repo "$repo_url" "$dir"
    i=$((i + 1))
  done

  i=0
  for entry in "${REPOS[@]}"; do
    local dir="${entry##*:}"
    if repo_has_changed "$dir" "${old_hashes[$i]}"; then
      log_info "$dir has new commits"
      changed=true
    else
      log_ok "$dir is unchanged"
    fi
    i=$((i + 1))
  done

  echo
  if $changed; then
    build_images "$@"
    restart_services
    log_ok "Update finished."
  else
    log_ok "No updates available — images are current."
  fi
}

main "$@"
