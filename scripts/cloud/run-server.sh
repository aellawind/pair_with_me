#!/usr/bin/env bash
#
# Long-lived Django development server for the "pair_with_me" app.
# Intended to run as a persistent terminal after scripts/cloud/start.sh has
# prepared the database.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}/pairwithme"
exec "${REPO_ROOT}/.venv/bin/python" manage.py runserver 0.0.0.0:8000
