#!/usr/bin/env bash
#
# Idempotent bootstrap for the "pair_with_me" wine pairing app.
#
# This is a 2017-era stack: Django 1.11 (needs Python 3.7, the newest interpreter
# it supports), a MySQL/MariaDB backend, and a React 15 / webpack 2 frontend
# (needs Node 10). None of those toolchains ship on a modern base image, so this
# script installs them itself and then prepares the repository: Python venv +
# backend deps, frontend deps, and the compiled webpack bundle.
#
# It is safe to run repeatedly; every step is guarded or naturally idempotent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${REPO_ROOT}/pairwithme"
VENV_DIR="${REPO_ROOT}/.venv"

echo "==> [install] Repo root: ${REPO_ROOT}"

# ---------------------------------------------------------------------------
# System dependencies: Python 3.7 (deadsnakes), MariaDB, build tooling
# ---------------------------------------------------------------------------
if ! command -v python3.7 >/dev/null 2>&1; then
  echo "==> [install] Installing Python 3.7 toolchain (deadsnakes) + build deps"
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
  sudo add-apt-repository -y ppa:deadsnakes/ppa
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3.7 python3.7-venv python3.7-dev python3.7-distutils \
    build-essential pkg-config \
    libmariadb-dev libmariadb-dev-compat
fi

if ! command -v mariadbd >/dev/null 2>&1; then
  echo "==> [install] Installing MariaDB server"
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
fi

# ---------------------------------------------------------------------------
# Node 10 (webpack 2 / babel 6 / React 15) via nvm
# ---------------------------------------------------------------------------
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "${NVM_DIR}/nvm.sh" ]; then
  echo "==> [install] Installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
# shellcheck disable=SC1091
. "${NVM_DIR}/nvm.sh"
nvm install 10 >/dev/null
nvm use 10 >/dev/null
# Ensure the Node 10 toolchain wins over any node shim earlier on PATH.
export PATH="$(dirname "$(nvm which 10)"):${PATH}"
echo "==> [install] Using Node $(node --version)"

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
# Frontend: dependencies + webpack bundle build
# ---------------------------------------------------------------------------
echo "==> [install] Installing frontend dependencies"
cd "${APP_DIR}"
npm install --no-audit --no-fund

echo "==> [install] Building webpack bundle"
node_modules/.bin/webpack --bail

echo "==> [install] Done."
