#!/usr/bin/env bash
# Self-contained, idempotent bootstrap for the Pair With Me app.
#
# This 2017-era stack pins old toolchains, so the environment builds them
# explicitly rather than relying on system defaults:
#   - Python 3.6 via Miniconda (Django 1.11.2 breaks on Python 3.7+, and conda
#     ships OpenSSL 1.1 so we avoid the OpenSSL 3 build issues of compiling old
#     CPython from source on Ubuntu 24.04).
#   - MySQL Connector/C 6.1 (conda-forge) which still provides the legacy
#     my_config.h / my_bool that the pinned mysqlclient 1.3.6 needs to compile.
#   - MariaDB server (apt) as the database.
#
# Designed to run from Cursor's default Ubuntu base image and to be safe to
# re-run: expensive steps are skipped when already present.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$REPO_ROOT/pairwithme"

CONDA_DIR="$HOME/miniconda3"
CONDA_ENV="pwm"
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh"

# 1. System packages: build toolchain, MariaDB server + client dev headers.
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  build-essential pkg-config curl ca-certificates \
  mariadb-server default-libmysqlclient-dev

# 2. Miniconda (provides a relocatable Python 3.6 toolchain with OpenSSL 1.1).
if [ ! -x "$CONDA_DIR/bin/conda" ]; then
  tmp_installer="$(mktemp --suffix=.sh)"
  curl -fsSL -o "$tmp_installer" "$MINICONDA_URL"
  bash "$tmp_installer" -b -p "$CONDA_DIR"
  rm -f "$tmp_installer"
fi

# shellcheck disable=SC1091
source "$CONDA_DIR/etc/profile.d/conda.sh"

# 3. Python 3.6 environment + legacy MySQL Connector/C for mysqlclient 1.3.6.
if ! conda env list | grep -q "/envs/${CONDA_ENV}\b"; then
  conda create -y -n "$CONDA_ENV" python=3.6
fi
conda activate "$CONDA_ENV"
if [ ! -f "$CONDA_PREFIX/include/my_config.h" ]; then
  conda install -y -c conda-forge mysql-connector-c
fi

cd "$APP_DIR"

# 4. Python dependencies (mysqlclient builds against the conda connector's
#    mysql_config, which is first on PATH inside the activated env).
pip install -r requirements.txt

# 5. Frontend dependencies + production bundle.
npm install
# Node 17+ ships OpenSSL 3, which the legacy webpack 2 hashing needs a shim for.
NODE_OPTIONS=--openssl-legacy-provider ./node_modules/.bin/webpack

echo "install.sh: bootstrap complete"
