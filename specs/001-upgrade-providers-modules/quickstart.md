# Quickstart Validation Guide: Terraform Provider & Module Upgrade

**Feature**: 001-upgrade-providers-modules
**Date**: 2026-07-07

This guide lets you verify the upgrade end-to-end from a clean checkout.
No GCP credentials are required for Steps 1–4. Step 5 (integration tests) requires Docker.

---

## Prerequisites

- Terraform 1.12+ (`terraform version`)
- tflint with GCP plugin (`tflint --version`)
- terraform-docs 0.18+ (`terraform-docs --version`)
- pre-commit (`pre-commit --version`)
- Docker and docker-compose (for Step 5 only)
- git

---

## Step 1: Verify No Legacy Version Constraints Remain

Run these greps from the repository root. All should return **no output**.

```bash
# Should return nothing — all required_version must be >= 1.12
grep -rn ">= 0\.13\|>= 1\.3\|>= 1\.5\|>= 1\.9" --include="versions.tf" .

# Should return nothing — no exact-pinned providers in stacks
grep -En '"[0-9]+\.[0-9]+\.[0-9]+"' stacks/example/versions.tf

# Should return nothing — no old < 7 upper bound remains; new upper bound is < 8
grep -rn '< 7"' --include="versions.tf" .
```

Expected: all three commands produce empty output.

---

## Step 2: Run `terraform validate` in Every Module

```bash
for dir in modules/networks/firewall-rules \
           modules/networks/routes \
           modules/networks/subnets \
           modules/networks/router-nat \
           modules/networks/vpc \
           modules/networks/vpn-classic \
           modules/networks/vpn-ha \
           modules/sql/postgresql \
           modules/workload/artifact-registry \
           examples/ha-vpn; do
  echo "=== $dir ==="
  terraform -chdir="$dir" init -backend=false -no-color
  terraform -chdir="$dir" validate -no-color
done
```

Expected: each `validate` prints `Success! The configuration is valid.`

---

## Step 3: Run `terraform init -upgrade` on the Stack

```bash
terraform -chdir=stacks/example init -upgrade -no-color
```

Expected:
- Provider downloads show `7.x` versions of google/google-beta (floor `>= 7.10`).
- Kubernetes provider resolves to `3.2.x`.
- Helm provider resolves to `3.2.x`.
- HTTP provider resolves to `3.6.x`.
- Lock file (`.terraform.lock.hcl`) is updated.

Commit the updated lock file:

```bash
git add stacks/example/.terraform.lock.hcl
git commit -m "chore(stacks/example): regenerate provider lock file after upgrade"
```

---

## Step 4: Run Unit Tests (Mock Provider — no GCP credentials)

```bash
# Run unit tests for each module
for dir in modules/networks/firewall-rules \
           modules/networks/routes \
           modules/networks/subnets \
           modules/networks/router-nat \
           modules/networks/vpc \
           modules/networks/vpn-classic \
           modules/networks/vpn-ha \
           modules/sql/postgresql \
           modules/workload/artifact-registry; do
  echo "=== $dir ==="
  terraform -chdir="$dir" test -no-color
done
```

Expected: each `terraform test` prints `0 assertions failed` and exits 0.

See [contracts/test-interface.md](contracts/test-interface.md) for what each module's
unit test validates.

---

## Step 5: Run Integration Tests (docker-compose GCP stack)

Start the local GCP emulator stack:

```bash
./tests/local-gcp-stack/init.sh
```

Expected output:
```
[fake-gcs] Listening on :4443
[postgres] database system is ready to accept connections
[local-registry] Starting up registry on port 5000
Local GCP stack ready. Environment vars exported.
```

Run integration tests:

```bash
./tests/run-integration-tests.sh
```

Expected: script prints `All integration tests passed.` and exits 0.

Tear down:

```bash
./tests/local-gcp-stack/teardown.sh
```

---

## Step 6: Run Pre-commit Checks

```bash
pre-commit run --all-files
```

Expected: all hooks (`terraform-fmt`, `tflint`, `terraform-docs-go`) exit 0 with
no reported failures.

---

## Step 7: Verify GKE Module Compatibility (optional, requires GCP access)

If GCP credentials are available, verify the GKE module upgrade:

```bash
export GOOGLE_PROJECT=<your-test-project>
terraform -chdir=stacks/example plan -no-color 2>&1 | grep -E "Plan:|Error:"
```

Expected: `Plan: N to add, M to change, 0 to destroy.` with no errors related to
deprecated attributes from the v32 → v44 GKE module upgrade.

---

## Validation Summary

| Step | Command | Expected outcome |
|---|---|---|
| 1 | `grep` version constraints | No legacy constraints found |
| 2 | `terraform validate` per module | All succeed |
| 3 | `terraform init -upgrade` on stack | Providers resolved at target versions |
| 4 | `terraform test` per module | 0 assertions failed |
| 5 | `./tests/run-integration-tests.sh` | All integration tests passed |
| 6 | `pre-commit run --all-files` | All hooks pass |
| 7 | `terraform plan` on stack (optional) | No deprecated-attribute errors |
