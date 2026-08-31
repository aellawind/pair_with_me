#!/usr/bin/env bash
#
# Long-lived Django development server for the "pair_with_me" app.
# Runs as a persistent terminal. It first ensures the database is up and seeded
# (scripts/cloud/start.sh is idempotent) and then serves on 0.0.0.0:8000.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

bash "${REPO_ROOT}/scripts/cloud/start.sh"

cd "${REPO_ROOT}/pairwithme"
exec "${REPO_ROOT}/.venv/bin/python" manage.py runserver 0.0.0.0:8000
