#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[floci] Stopping local GCP stack..."
docker compose -f "${SCRIPT_DIR}/docker-compose.yml" down -v
echo "[floci] Local GCP stack stopped."
