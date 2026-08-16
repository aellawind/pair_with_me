#!/usr/bin/env bash
#
# Idempotent repository bootstrap for the "pair_with_me" wine pairing app.
#
# System-level dependencies (Python 3.7 via deadsnakes, MariaDB server + client
# dev headers, Node 10 via nvm, build tooling) are provided by the base
# environment. This script only prepares repository-derived state: the Python
# virtualenv, backend dependencies, frontend dependencies, and the compiled
# webpack bundle. It is safe to run repeatedly.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${REPO_ROOT}/pairwithme"
VENV_DIR="${REPO_ROOT}/.venv"

echo "==> [install] Repo root: ${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Backend: Python 3.7 virtualenv + pinned dependencies
# ---------------------------------------------------------------------------
if [ ! -x "${VENV_DIR}/bin/python" ]; then
  echo "==> [install] Creating Python 3.7 virtualenv"
  python3.7 -m venv "${VENV_DIR}"
fi

echo "==> [install] Installing backend dependencies"
# Django 1.11 / mysqlclient 1.4.x predate modern packaging metadata, so pin the
# toolchain to versions that still understand them.
"${VENV_DIR}/bin/python" -m pip install --upgrade "pip<21" "setuptools<45" wheel
"${VENV_DIR}/bin/pip" install -r "${APP_DIR}/requirements.txt"

# ---------------------------------------------------------------------------
# Frontend: Node 10 (webpack 2 / babel 6 / React 15) + bundle build
# ---------------------------------------------------------------------------
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
. "${NVM_DIR}/nvm.sh"
nvm install 10 >/dev/null
nvm use 10 >/dev/null
# Ensure the Node 10 toolchain wins over any node shim earlier on PATH.
export PATH="$(dirname "$(nvm which 10)"):${PATH}"

echo "==> [install] Installing frontend dependencies"
cd "${APP_DIR}"
npm install --no-audit --no-fund

echo "==> [install] Building webpack bundle"
node_modules/.bin/webpack --bail

echo "==> [install] Done."
