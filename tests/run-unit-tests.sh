#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

MODULE_DIRS=(
  "modules/networks/firewall-rules"
  "modules/networks/routes"
  "modules/networks/subnets"
  "modules/networks/router-nat"
  "modules/networks/vpc"
  "modules/networks/vpn-classic"
  "modules/networks/vpn-ha"
  "modules/sql/postgresql"
  "modules/workload/artifact-registry"
  "modules/data/dataproc"
  "modules/data/bigquery"
  "modules/storage/gcs"
  "modules/security/secret-manager"
  "modules/security/kms"
  "modules/security/dlp"
  "modules/governance/dataplex"
  "modules/networks/psc"
  "modules/networks/load-balancer"
  "modules/networks/secure-web-proxy"
  "modules/workload/cloud-run"
  "modules/api/api-gateway"
  "modules/api/cloud-endpoints"
  "modules/observability/cloud-logging"
)

for dir in "${MODULE_DIRS[@]}"; do
  module_path="${REPO_ROOT}/${dir}"
  echo "=== Running unit tests: ${dir} ==="

  if [ ! -d "${module_path}/tests" ]; then
    echo "  SKIP: no tests/ directory"
    continue
  fi

  if terraform -chdir="${module_path}" test -no-color 2>&1; then
    echo "  PASS"
  else
    echo "  FAIL"
    FAILED=$((FAILED + 1))
  fi
done

if [ "${FAILED}" -gt 0 ]; then
  echo ""
  echo "RESULT: ${FAILED} module(s) failed unit tests."
  exit 1
else
  echo ""
  echo "RESULT: All unit tests passed."
fi
