#!/usr/bin/env bash
#
# Per-boot runtime initialisation for the "pair_with_me" app.
#
# Brings up MariaDB on port 3307 (matching pairwithme/settings.py), ensures the
# expected root credential and PAIR_WITH_ME_MAIN database exist, applies Django
# migrations, and seeds the demo wine/food pairings the first time only. It is
# idempotent and returns once the database is ready; the Django dev server is
# run separately as a long-lived terminal.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${REPO_ROOT}/pairwithme"
VENV_PY="${REPO_ROOT}/.venv/bin/python"
SOCK="/run/mysqld/mysqld.sock"
DB_PORT="3307"
DB_NAME="PAIR_WITH_ME_MAIN"
DB_PASS="password"

echo "==> [start] Ensuring MariaDB runtime directory"
sudo install -d -o mysql -g mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
  echo "==> [start] Initialising MariaDB data directory"
  sudo mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

if ! sudo mariadb-admin --socket="${SOCK}" ping >/dev/null 2>&1; then
  echo "==> [start] Starting MariaDB on port ${DB_PORT}"
  sudo -b mariadbd --user=mysql --port="${DB_PORT}" --socket="${SOCK}" \
    >/tmp/mariadb.log 2>&1
  for _ in $(seq 1 30); do
    if sudo mariadb-admin --socket="${SOCK}" ping >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
fi

if ! sudo mariadb-admin --socket="${SOCK}" ping >/dev/null 2>&1; then
  echo "!! [start] MariaDB did not become ready" >&2
  tail -n 20 /tmp/mariadb.log >&2 || true
  exit 1
fi
echo "==> [start] MariaDB is ready"

# Connect either via passwordless socket (fresh datadir) or with the configured
# password (already-provisioned datadir), whichever currently works.
if sudo mariadb --socket="${SOCK}" -e "SELECT 1" >/dev/null 2>&1; then
  MYSQL=(sudo mariadb --socket="${SOCK}")
else
  MYSQL=(mariadb -u root "-p${DB_PASS}" --socket="${SOCK}")
fi

echo "==> [start] Ensuring root credential and database"
"${MYSQL[@]}" <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${DB_PASS}');
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4;
FLUSH PRIVILEGES;
SQL

echo "==> [start] Applying Django migrations"
(cd "${APP_DIR}" && "${VENV_PY}" manage.py migrate --noinput)

WINE_COUNT="$(mariadb -u root "-p${DB_PASS}" --socket="${SOCK}" -N -B \
  -e "SELECT COUNT(*) FROM ${DB_NAME}.api_wine" 2>/dev/null || echo 0)"
if [ "${WINE_COUNT:-0}" = "0" ]; then
  echo "==> [start] Seeding demo wine/food pairings"
  (cd "${APP_DIR}" && "${VENV_PY}" manage.py populate_db)
else
  echo "==> [start] Database already seeded (${WINE_COUNT} wines); skipping"
fi

echo "==> [start] Done. Run the Django dev server with:"
echo "    scripts/cloud/run-server.sh"
