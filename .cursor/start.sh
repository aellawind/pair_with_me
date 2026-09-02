#!/usr/bin/env bash
# Per-boot service reconciliation for the Pair With Me app.
# Brings up MariaDB (on the port 3307 the Django settings expect), ensures the
# database + credentials exist, applies migrations, and seeds demo data once.
# The Django dev server itself runs as a persistent terminal (see terminals).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$REPO_ROOT/pairwithme"

DB_NAME="PAIR_WITH_ME_MAIN"
DB_PASS="password"
DB_PORT="3307"

# 1. Start MariaDB on port 3307 if it is not already listening.
if ! ss -ltn 2>/dev/null | grep -q ":${DB_PORT} "; then
  sudo bash -c "nohup mariadbd-safe --port=${DB_PORT} --bind-address=127.0.0.1 >/tmp/mariadb.log 2>&1 &"
fi

# Wait for the server socket to come up.
for _ in $(seq 1 60); do
  ss -ltn 2>/dev/null | grep -q ":${DB_PORT} " && break
  sleep 1
done

# The pinned mysqlclient/connector defaults to /tmp/mysql.sock for
# HOST=localhost connections; point it at the real MariaDB socket.
if [ -S /run/mysqld/mysqld.sock ]; then
  ln -sf /run/mysqld/mysqld.sock /tmp/mysql.sock
fi

# 2. Ensure database + root credentials the Django settings expect.
# On a snapshot boot root already uses a native password; on a fresh datadir it
# still authenticates via the unix socket, so fall back to sudo in that case.
if mysql -uroot -p"${DB_PASS}" -e 'SELECT 1' >/dev/null 2>&1; then
  MYSQL=(mysql -uroot -p"${DB_PASS}")
else
  MYSQL=(sudo mariadb)
fi

"${MYSQL[@]}" <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8;
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${DB_PASS}');
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED VIA mysql_native_password USING PASSWORD('${DB_PASS}');
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

# 3. Apply migrations and seed demo pairings once (idempotent).
# shellcheck disable=SC1091
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate pwm
cd "$APP_DIR"

python manage.py migrate --noinput

WINE_COUNT="$(python manage.py shell -c 'from api.models import Wine; print(Wine.objects.count())' 2>/dev/null | tail -1)"
if [ "${WINE_COUNT:-0}" = "0" ]; then
  python manage.py populate_db
fi

echo "start.sh: MariaDB ready on 127.0.0.1:${DB_PORT}, database ${DB_NAME} migrated and seeded"
