#!/usr/bin/env bash
# Long-running terminal: the Django development server on port 8000.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"
ensure_mariadb_running
cd "$APP_DIR"
exec "$PY" manage.py runserver 0.0.0.0:8000
