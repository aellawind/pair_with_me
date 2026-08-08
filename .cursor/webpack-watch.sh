#!/usr/bin/env bash
# Long-running terminal: rebuild the frontend bundle on source changes.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"
cd "$APP_DIR"
exec env PATH="$NODE_BIN:$PATH" node_modules/.bin/webpack --watch
