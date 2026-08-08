#!/usr/bin/env bash
# Shared helpers and pinned versions for the pair_with_me Cloud Agent environment.
# The 2017-era stack needs runtimes that are not the VM defaults, so we layer
# them in per-user locations (no system Python/Node changes):
#   - Python 3.6 via Miniconda env "pairwithme" (Django 1.11.2 supports <=3.6)
#   - Node 8 via nvm (Webpack 2 / Babel 6 do not run on modern Node)
#   - MariaDB 10.x from apt, listening on port 3307 to match settings.py

set -euo pipefail

CONDA_DIR="$HOME/miniconda3"
CONDA_ENV="pairwithme"
PY="$CONDA_DIR/envs/$CONDA_ENV/bin/python"
PIP="$CONDA_DIR/envs/$CONDA_ENV/bin/pip"
NODE_VERSION="8.17.0"
NODE_BIN="$HOME/.nvm/versions/node/v$NODE_VERSION/bin"
MYSQL_SOCK="/run/mysqld/mysqld.sock"
DB_NAME="PAIR_WITH_ME_MAIN"
DB_PASSWORD="password"

# Resolve the repository root (parent of this .cursor directory) regardless of
# where the lifecycle command is invoked from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/pairwithme"

log() { echo "[pairwithme] $*"; }

# Start MariaDB (idempotent) and block until it accepts connections. /run is a
# tmpfs that is empty on every boot, so the socket dir must be recreated.
ensure_mariadb_running() {
  sudo mkdir -p /run/mysqld
  sudo chown mysql:mysql /run/mysqld
  if sudo mariadb-admin --socket="$MYSQL_SOCK" ping >/dev/null 2>&1; then
    log "MariaDB already running."
    return 0
  fi
  log "Starting MariaDB on port 3307..."
  sudo bash -c "setsid mariadbd-safe --datadir=/var/lib/mysql >/tmp/mariadb-boot.log 2>&1 < /dev/null &"
  for _ in $(seq 1 60); do
    if sudo mariadb-admin --socket="$MYSQL_SOCK" ping >/dev/null 2>&1; then
      log "MariaDB is up."
      return 0
    fi
    sleep 1
  done
  log "ERROR: MariaDB did not become ready. Log:"
  sudo tail -n 40 /tmp/mariadb-boot.log || true
  return 1
}
