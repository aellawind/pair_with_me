#!/usr/bin/env bash
# Idempotent repository bootstrap for the Pair With Me app.
# Refreshes Python + JS dependencies and rebuilds the webpack bundle.
# Assumes the base image/snapshot already provides:
#   - Miniconda at $HOME/miniconda3 with a "pwm" env (Python 3.6 + mysql-connector-c)
#   - MariaDB server + client (apt)
#   - Node.js (nvm) toolchain
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$REPO_ROOT/pairwithme"

# Activate the Django-compatible Python environment.
# shellcheck disable=SC1091
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate pwm

cd "$APP_DIR"

# Python dependencies (mysqlclient builds against the conda mysql-connector-c
# that provides the legacy my_config.h / my_bool the pinned 1.3.6 needs).
pip install -r requirements.txt

# Frontend dependencies + production bundle.
npm install
# Node 17+ ships OpenSSL 3, which the legacy webpack 2 hashing needs a shim for.
NODE_OPTIONS=--openssl-legacy-provider ./node_modules/.bin/webpack

echo "install.sh: bootstrap complete"
