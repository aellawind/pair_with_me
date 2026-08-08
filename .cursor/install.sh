#!/usr/bin/env bash
# Idempotent setup for the pair_with_me dev environment. Safe to run repeatedly.
# Provisions the legacy runtimes, installs dependencies, builds the frontend
# bundle, applies migrations and seeds the database.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# --- System packages: MariaDB server/client + headers to build mysqlclient ----
if ! dpkg -s mariadb-server >/dev/null 2>&1; then
  log "Installing MariaDB and build dependencies..."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mariadb-server mariadb-client default-libmysqlclient-dev build-essential pkg-config
fi

# Pin MariaDB to port 3307 (settings.py) and a predictable socket.
if [ ! -f /etc/mysql/mariadb.conf.d/99-pairwithme.cnf ]; then
  log "Configuring MariaDB for port 3307..."
  printf '[mysqld]\nport=3307\nbind-address=127.0.0.1\nskip-name-resolve\n' \
    | sudo tee /etc/mysql/mariadb.conf.d/99-pairwithme.cnf >/dev/null
fi

# --- Python 3.6 via Miniconda -------------------------------------------------
if [ ! -x "$CONDA_DIR/bin/conda" ]; then
  log "Installing Miniconda..."
  curl -fsSL -o /tmp/miniconda.sh \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash /tmp/miniconda.sh -b -p "$CONDA_DIR"
fi
if [ ! -x "$PY" ]; then
  log "Creating Python 3.6 conda env '$CONDA_ENV'..."
  "$CONDA_DIR/bin/conda" create -y -n "$CONDA_ENV" -c conda-forge --override-channels python=3.6
fi

# --- Node 8 via nvm -----------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  log "Installing nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
if [ ! -x "$NODE_BIN/node" ]; then
  log "Installing Node $NODE_VERSION..."
  nvm install "$NODE_VERSION"
fi

# --- Python dependencies ------------------------------------------------------
log "Installing Python requirements..."
"$PIP" install -r "$APP_DIR/requirements.txt"

# --- Frontend dependencies + bundle ------------------------------------------
log "Installing npm dependencies..."
( cd "$APP_DIR" && PATH="$NODE_BIN:$PATH" npm install )
log "Building webpack bundle..."
( cd "$APP_DIR" && PATH="$NODE_BIN:$PATH" node_modules/.bin/webpack )

# --- Database provisioning ----------------------------------------------------
ensure_mariadb_running

if ! mysql -u root -p"$DB_PASSWORD" -e 'SELECT 1' >/dev/null 2>&1; then
  log "Provisioning database user/password..."
  sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4;
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_PASSWORD');
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
fi
mysql -u root -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4;"

# --- Migrations + seed data ---------------------------------------------------
log "Applying migrations..."
( cd "$APP_DIR" && "$PY" manage.py migrate --noinput )

# populate_db uses create() (not idempotent), so only seed an empty table.
WINE_COUNT="$(mysql -u root -p"$DB_PASSWORD" -N -B -e "SELECT COUNT(*) FROM api_wine;" "$DB_NAME" 2>/dev/null || echo 0)"
if [ "${WINE_COUNT:-0}" = "0" ]; then
  log "Seeding sample wine/food pairings..."
  ( cd "$APP_DIR" && "$PY" manage.py populate_db )
else
  log "Database already seeded ($WINE_COUNT wines); skipping."
fi

log "Install complete."
