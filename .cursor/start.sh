#!/usr/bin/env bash
# Per-boot startup for the pair_with_me Cloud Agent environment.
# Brings up MariaDB on the port the app expects, ensures the schema exists,
# and seeds demo data on first run. Must be idempotent and safe to re-run.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/pairwithme"
PY="$HOME/miniconda3/envs/pwm/bin/python"

# Django's settings use HOST=localhost PORT=3307, so mysqlclient connects over
# the local socket. mysqlclient's compiled default socket path is
# /var/run/mysqld/mysqld.sock, so MariaDB must expose it there.
SOCK="/var/run/mysqld/mysqld.sock"
DB_PORT=3307
DB_NAME=PAIR_WITH_ME_MAIN
DB_PASS=password

echo "==> Ensuring MariaDB runtime directory"
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld

if sudo mysqladmin --socket="$SOCK" ping >/dev/null 2>&1; then
  echo "==> MariaDB already running"
else
  echo "==> Starting MariaDB on port ${DB_PORT}"
  sudo bash -c "nohup mariadbd --user=mysql --port=${DB_PORT} --socket=${SOCK} > /var/log/mariadb-pwm.log 2>&1 &"
  for _ in $(seq 1 60); do
    if sudo mysqladmin --socket="$SOCK" ping >/dev/null 2>&1; then break; fi
    sleep 1
  done
  sudo mysqladmin --socket="$SOCK" ping >/dev/null 2>&1 || {
    echo "MariaDB failed to start; see /var/log/mariadb-pwm.log" >&2
    sudo tail -n 30 /var/log/mariadb-pwm.log >&2 || true
    exit 1
  }
fi

echo "==> Ensuring root password + application database"
# On a fresh (non-snapshot) data dir, root authenticates via unix_socket, so
# this sudo connection works to set the password. On a snapshot the password is
# already set and this branch is skipped.
if ! mysql -u root -p"${DB_PASS}" --socket="$SOCK" -e "SELECT 1" >/dev/null 2>&1; then
  sudo mariadb --socket="$SOCK" -e \
    "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${DB_PASS}'); FLUSH PRIVILEGES;"
fi
mysql -u root -p"${DB_PASS}" --socket="$SOCK" \
  -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4;"

echo "==> Applying migrations"
cd "$APP_DIR"
"$PY" manage.py migrate --noinput

WINE_COUNT="$(mysql -u root -p"${DB_PASS}" --socket="$SOCK" -N -B -D "${DB_NAME}" \
  -e "SELECT COUNT(*) FROM api_wine;" 2>/dev/null || echo 0)"
if [ "${WINE_COUNT:-0}" -eq 0 ]; then
  echo "==> Seeding demo data (populate_db)"
  "$PY" manage.py populate_db
else
  echo "==> Demo data already present (${WINE_COUNT} wines); skipping seed"
fi

echo "==> start.sh complete"
