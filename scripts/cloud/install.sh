#!/usr/bin/env bash
#
# Idempotent bootstrap for the "pair_with_me" wine pairing app.
#
# This is a 2017-era stack: Django 1.11 (needs Python 3.7, the newest interpreter
# it supports), a MySQL/MariaDB backend, and a React 15 / webpack 2 frontend
# (needs Node 10). None of those toolchains ship on a modern base image, so this
# script installs them and then prepares the repository: a Python 3.7 venv with
# the backend deps, the frontend deps, and the compiled webpack bundle.
#
# Durable, source-derived setup only. Runtime services (MariaDB, the dev server)
# are started by scripts/cloud/start.sh and .cursor/environment.json terminals.
# Safe to run repeatedly; every step is guarded or naturally idempotent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${REPO_ROOT}/pairwithme"
VENV_DIR="${REPO_ROOT}/.venv"

echo "==> [install] Repo root: ${REPO_ROOT}"

# ---------------------------------------------------------------------------
# System dependencies
#   - Python 3.7 (deadsnakes): required by Django 1.11.
#   - MariaDB server: the database engine.
#   - libmysqlclient-dev (MySQL 8.0 client headers): mysqlclient 1.4.6 builds
#     against these because they still expose the MYSQL.reconnect member that
#     the newer MariaDB Connector/C headers removed. Do NOT install
#     libmariadb-dev(-compat) alongside it; they collide on mysql_config.
# ---------------------------------------------------------------------------
NEED_APT=0
command -v python3.7      >/dev/null 2>&1 || NEED_APT=1
command -v mariadbd       >/dev/null 2>&1 || NEED_APT=1
command -v mysql_config   >/dev/null 2>&1 || NEED_APT=1

if [ "${NEED_APT}" = "1" ]; then
  echo "==> [install] Installing system packages"
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
  if ! command -v python3.7 >/dev/null 2>&1; then
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update -y
  fi
  # Remove MariaDB client dev headers if present so the MySQL ones win.
  sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y \
    libmariadb-dev libmariadb-dev-compat 2>/dev/null || true
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3.7 python3.7-venv python3.7-dev python3.7-distutils \
    build-essential pkg-config \
    libmysqlclient-dev \
    mariadb-server
fi

echo "==> [install] Python $(python3.7 --version), $(mysql_config --version) client, $(mariadbd --version | head -1)"

# ---------------------------------------------------------------------------
# Node 10 (webpack 2 / babel 6 / React 15) via nvm.
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
# Ensure the Node 10 toolchain wins over any newer node earlier on PATH.
export PATH="$(dirname "$(nvm which 10)"):${PATH}"
echo "==> [install] Using Node $(node --version) / npm $(npm --version)"

# ---------------------------------------------------------------------------
# Backend: Python 3.7 virtualenv + pinned dependencies.
# ---------------------------------------------------------------------------
if [ ! -x "${VENV_DIR}/bin/python" ]; then
  echo "==> [install] Creating Python 3.7 virtualenv"
  python3.7 -m venv "${VENV_DIR}"
fi

echo "==> [install] Installing backend dependencies"
# Django 1.11 / mysqlclient 1.4.x predate modern packaging metadata, so pin the
# build toolchain to versions that still understand them.
"${VENV_DIR}/bin/python" -m pip install --upgrade "pip<21" "setuptools<45" wheel
"${VENV_DIR}/bin/pip" install -r "${APP_DIR}/requirements.txt"

# ---------------------------------------------------------------------------
# Frontend: dependencies + webpack bundle build.
# ---------------------------------------------------------------------------
echo "==> [install] Installing frontend dependencies"
cd "${APP_DIR}"
npm install --no-audit --no-fund

echo "==> [install] Building webpack bundle"
node_modules/.bin/webpack --bail

echo "==> [install] Done."
