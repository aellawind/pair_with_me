#!/usr/bin/env bash
#
# Environment "start" entrypoint for the "pair_with_me" app.
# Prepares the database (idempotent) and then hands off to the long-lived
# Django development server, which stays attached for the lifetime of the
# container.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${DIR}/start.sh"
exec bash "${DIR}/run-server.sh"
