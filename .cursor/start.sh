#!/usr/bin/env bash
# Per-boot startup: bring MariaDB up (the datadir is persisted, but /run is not)
# so the dev-server terminals can connect. Returns once the DB is reachable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

ensure_mariadb_running
log "Start complete; MariaDB reachable on port 3307."
