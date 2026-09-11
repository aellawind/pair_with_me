#!/usr/bin/env bash
# Idempotent repository bootstrap for the pair_with_me Cloud Agent environment.
#
# This app is a legacy stack whose pinned runtimes do not run on a modern OS:
#   * Django 1.11 needs Python <= 3.6 (it uses `async` as an arg name, reserved
#     in 3.7+). Python 3.6 needs OpenSSL 1.1, so it is provided via a Miniconda
#     env rather than a source build on Ubuntu 24.04 (which ships OpenSSL 3).
#   * webpack 2 / babel 6 need an old Node -> Node 8 via nvm.
#   * The app talks to MySQL -> MariaDB (started later by start.sh).
#
# Everything here is durable, one-time setup (installed into the build's baseline
# snapshot). Services and the database are handled per-boot by start.sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/pairwithme"

CONDA_HOME="$HOME/miniconda3"
CONDA_ENV="pwm"
PY_VERSION="3.6"
NODE_VERSION="8.17.0"

echo "==> [1/5] Installing system packages (MariaDB + MySQL client dev libs)"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq \
  mariadb-server \
  default-libmysqlclient-dev \
  build-essential \
  pkg-config \
  curl

echo "==> [2/5] Ensuring Miniconda + Python ${PY_VERSION} env '${CONDA_ENV}'"
if [ ! -x "$CONDA_HOME/bin/conda" ]; then
  curl -fsSL -o /tmp/miniconda.sh \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash /tmp/miniconda.sh -b -p "$CONDA_HOME"
  rm -f /tmp/miniconda.sh
fi
if [ ! -x "$CONDA_HOME/envs/$CONDA_ENV/bin/python" ]; then
  # Use conda-forge exclusively to avoid the anaconda default-channel ToS gate
  # and to get a Python 3.6 build with OpenSSL 1.1.
  "$CONDA_HOME/bin/conda" create -y -n "$CONDA_ENV" \
    -c conda-forge --override-channels "python=${PY_VERSION}"
fi
PY="$CONDA_HOME/envs/$CONDA_ENV/bin/python"

echo "==> [3/5] Installing Python (Django) dependencies"
# Old pip/setuptools are needed to build the pinned-era packages cleanly.
"$PY" -m pip install --upgrade "pip<21" "setuptools<45" wheel
"$PY" -m pip install -r "$APP_DIR/requirements.txt"

echo "==> [4/5] Ensuring Node ${NODE_VERSION} via nvm"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
NODE_BIN="$NVM_DIR/versions/node/v${NODE_VERSION}/bin"

echo "==> [5/5] Installing frontend deps and building the webpack bundle"
cd "$APP_DIR"
PATH="$NODE_BIN:$PATH" npm install
PATH="$NODE_BIN:$PATH" ./node_modules/.bin/webpack --config webpack.config.js

echo "==> install.sh complete"
