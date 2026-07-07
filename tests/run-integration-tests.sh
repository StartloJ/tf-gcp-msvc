#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_DIR="${REPO_ROOT}/stacks/example"

echo "=== Running integration tests: stacks/example ==="

if [ ! -f "${STACK_DIR}/tests/integration.tftest.hcl" ]; then
  echo "ERROR: integration test file not found at stacks/example/tests/integration.tftest.hcl"
  exit 1
fi

if terraform -chdir="${STACK_DIR}" test -test-directory=tests/ -filter=integration -no-color 2>&1; then
  echo ""
  echo "All integration tests passed."
else
  echo ""
  echo "ERROR: Integration tests failed."
  exit 1
fi
