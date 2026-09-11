#!/usr/bin/env bash
# Idempotent repository bootstrap for the pair_with_me Cloud Agent environment.
# Runs after the repository is checked out. Installs backend/frontend
# dependencies and builds the webpack bundle. Does NOT start services or touch
# the database (that belongs in start.sh).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/pairwithme"

# Django 1.11 needs Python 3.6 (which in turn needs OpenSSL 1.1); this is
# provided by a conda env baked into the base snapshot.
CONDA_BIN="$HOME/miniconda3/envs/pwm/bin"

# webpack 2 / babel 6 need an old Node; use the nvm-managed Node 8 from the snapshot.
export NVM_DIR="$HOME/.nvm"
NODE8_BIN="$NVM_DIR/versions/node/v8.17.0/bin"

echo "==> Installing Python (Django) dependencies"
"$CONDA_BIN/pip" install -r "$APP_DIR/requirements.txt"

echo "==> Installing frontend (npm) dependencies"
cd "$APP_DIR"
PATH="$NODE8_BIN:$PATH" npm install

echo "==> Building webpack bundle"
PATH="$NODE8_BIN:$PATH" ./node_modules/.bin/webpack --config webpack.config.js

echo "==> install.sh complete"
