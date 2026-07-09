# Quickstart Validation Guide: AI/ML Platform Shared Modules

**Feature**: `002-ai-ml-modules` | **Date**: 2026-07-08

## Prerequisites

- Terraform >= 1.12 installed (`terraform version`)
- `pre-commit` installed (`pre-commit --version`)
- `tflint` installed (`tflint --version`)
- `terraform-docs` installed (`terraform-docs --version`)
- Repository cloned; all existing tests passing (`./tests/run-unit-tests.sh` exits 0)

## Step 1 — Verify Module Directory Structure

After implementation, each new module must have the required files:

```bash
for category in networks workload security governance data storage api observability; do
  for dir in modules/$category/*/; do
    [ -d "$dir" ] || continue
    for f in main.tf variables.tf outputs.tf versions.tf tests/unit.tftest.hcl; do
      [ -f "${dir}${f}" ] && echo "OK: ${dir}${f}" || echo "MISSING: ${dir}${f}"
    done
  done
done
# Expected: all lines print "OK: ..."
```

## Step 2 — All Module Unit Tests Pass

```bash
./tests/run-unit-tests.sh
# Expected:
# - PASS for all existing 9 modules (no regressions)
# - PASS for all 13 new modules
# - "RESULT: All unit tests passed."
```

Individual module test (example — security/kms):
```bash
terraform -chdir=modules/security/kms test -no-color
# Expected: Success! N passed, 0 failed.
```

## Step 3 — Pre-commit Gates

```bash
pre-commit run --all-files
# Expected: terraform-fmt, tflint, terraform-docs-go all show "Passed"
```

## Step 4 — Naming Convention Compliance

```bash
# No hardcoded resource names in new module main.tf files
grep -rn '"dpc-\|"bkt-\|"cr-\|"kr-\|"lake-\|"logsink-\|"psc-\|"swp-\|"lb-\|"apigw-\|"dlpt-\|"ds_' \
  modules/security/ modules/governance/ modules/data/ modules/storage/ \
  modules/api/ modules/observability/ modules/networks/psc \
  modules/networks/load-balancer modules/networks/secure-web-proxy \
  modules/workload/cloud-run \
  --include="main.tf"
# Expected: no output (all names assembled from variables, not hardcoded)
```

## Step 5 — Security Constraints Validation

```bash
# KMS keys have prevent_destroy
grep -rn 'prevent_destroy' modules/security/kms/main.tf
# Expected: at least one line showing prevent_destroy = true in a lifecycle block

# Secret plaintext not in outputs
grep -rn 'initial_value\|plaintext\|secret_data' modules/security/secret-manager/outputs.tf
# Expected: no output (plaintext never exposed)

# Cloud Run prd auth gate
grep -A5 'validation' modules/workload/cloud-run/variables.tf | grep -q 'prd'
echo "Cloud Run prd auth gate: $([[ $? -eq 0 ]] && echo OK || echo MISSING)"
# Expected: Cloud Run prd auth gate: OK
```

## Step 6 — Labels Interface on All New Modules

```bash
for d in modules/security/* modules/governance/* modules/data/* modules/storage/* \
          modules/api/* modules/observability/* \
          modules/networks/psc modules/networks/load-balancer \
          modules/networks/secure-web-proxy modules/workload/cloud-run; do
  [ -f "$d/variables.tf" ] || continue
  grep -q 'variable "labels"' "$d/variables.tf" \
    && echo "OK: $d" || echo "MISSING: $d"
done
# Expected: all lines print "OK: ..."
```

## Step 7 — PSC Module Validation

```bash
# Verify PSC module supports both types
terraform -chdir=modules/networks/psc test -no-color
# Expected: both plan_google_apis_type and plan_service_attachment_type runs pass

# Verify psc_type validation
cat modules/networks/psc/variables.tf | grep -A5 'psc_type'
# Expected: validation block with contains(["google-apis", "service-attachment"])
```

## Step 8 — Secure Web Proxy Module Validation

```bash
terraform -chdir=modules/networks/secure-web-proxy test -no-color
# Expected: plan runs pass for both default-deny and allow-with-exceptions configurations

# Verify default action is "deny"
grep -A3 'default_action' modules/networks/secure-web-proxy/variables.tf | grep 'default'
# Expected: default = "deny"
```

## Step 9 — DR Configuration Validation

```bash
# GCS DR: dr_replication_region variable exists and validation blocks source ≠ DR region
grep -A10 'dr_replication_region' modules/storage/gcs/variables.tf | grep -q 'validation'
echo "GCS DR validation: $([[ $? -eq 0 ]] && echo OK || echo MISSING)"

# Dataproc DR: enable_dr_standby and dr_cluster_name output exist
grep -q 'enable_dr_standby' modules/data/dataproc/variables.tf && echo "OK: dataproc DR var"
grep -q 'dr_cluster_name' modules/data/dataproc/outputs.tf && echo "OK: dataproc DR output"
```

## Step 10 — Run-unit-tests.sh Coverage

```bash
# All 13 new modules included in the test runner
for module in security/secret-manager security/kms security/dlp \
              governance/dataplex data/dataproc data/bigquery \
              storage/gcs api/api-gateway api/cloud-endpoints \
              observability/cloud-logging networks/psc \
              networks/load-balancer networks/secure-web-proxy \
              workload/cloud-run; do
  grep -q "modules/$module" tests/run-unit-tests.sh \
    && echo "OK: $module" || echo "MISSING from runner: $module"
done
# Expected: all lines print "OK: ..."
```

## Validation Summary

| Step | Check | Expected |
|---|---|---|
| 1 | Module directory structure | All 5 files present per module |
| 2 | Unit tests | 22 modules pass, 0 failures |
| 3 | Pre-commit | terraform-fmt, tflint, terraform-docs-go all green |
| 4 | Naming compliance | Zero hardcoded names in main.tf files |
| 5 | Security constraints | KMS prevent_destroy, no secret output, Cloud Run prd gate |
| 6 | Labels interface | All 13 new modules declare `variable "labels"` |
| 7 | PSC module | Both psc_type modes tested and validated |
| 8 | Secure Web Proxy | Default-deny confirmed, unit tests pass |
| 9 | DR configuration | GCS + Dataproc DR variables and outputs verified |
| 10 | Test runner coverage | All 13 new modules in run-unit-tests.sh |
