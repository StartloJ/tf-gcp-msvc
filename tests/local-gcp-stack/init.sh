#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[floci] Starting local GCP stack..."
docker compose -f "${SCRIPT_DIR}/docker-compose.yml" up -d

echo "[floci] Waiting for fake-gcs (port 4443)..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:4443/storage/v1/b >/dev/null 2>&1; then
    echo "[floci] fake-gcs ready."
    break
  fi
  sleep 1
  if [ "$i" -eq 30 ]; then
    echo "[floci] ERROR: fake-gcs did not become ready in time."
    exit 1
  fi
done

echo "[floci] Waiting for postgres (port 5432)..."
for i in $(seq 1 30); do
  if docker compose -f "${SCRIPT_DIR}/docker-compose.yml" exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
    echo "[floci] postgres ready."
    break
  fi
  sleep 1
  if [ "$i" -eq 30 ]; then
    echo "[floci] ERROR: postgres did not become ready in time."
    exit 1
  fi
done

echo "[floci] Waiting for local-registry (port 5000)..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:5000/v2/ >/dev/null 2>&1; then
    echo "[floci] local-registry ready."
    break
  fi
  sleep 1
  if [ "$i" -eq 30 ]; then
    echo "[floci] ERROR: local-registry did not become ready in time."
    exit 1
  fi
done

export STORAGE_EMULATOR_HOST="http://localhost:4443"
export CLOUDSDK_CORE_PROJECT="test-project"
export GOOGLE_OAUTH_ACCESS_TOKEN="fake-token"
export TF_VAR_project_id="test-project"

echo "[floci] Local GCP stack ready. Environment vars exported."
echo "  STORAGE_EMULATOR_HOST=${STORAGE_EMULATOR_HOST}"
echo "  CLOUDSDK_CORE_PROJECT=${CLOUDSDK_CORE_PROJECT}"
echo "  GOOGLE_OAUTH_ACCESS_TOKEN=${GOOGLE_OAUTH_ACCESS_TOKEN}"
