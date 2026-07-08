# Contract: State Migration Plan for Resource Renames

**Feature**: 001-upgrade-providers-modules (US5)
**Date**: 2026-07-08
**Scope**: `stacks/example/` only — the only stack with an applied state in this repo.

---

## Strategy

Prefer **`moved {}` blocks** (Terraform 1.1+) over CLI `terraform state mv` because
`moved {}` blocks are self-documenting in HCL and applied atomically during
`terraform plan / apply`. Use CLI `terraform state mv` only as a fallback for resource
types that do not support `moved {}`.

After all renames are applied and verified (`terraform plan` shows 0 destroy, 0 create),
the `moved {}` blocks should be retained for one release cycle then removed.

---

## `moved {}` Block Pattern

```hcl
# In stacks/example/moved.tf
moved {
  from = google_compute_network.example_main_vpc
  to   = google_compute_network.vpc
}
```

---

## Resources to Rename in `stacks/example/`

> **Note**: Actual resource addresses must be confirmed with `terraform state list`
> before applying. The addresses below are derived from the current HCL source.
> Verify each with: `terraform -chdir=stacks/example state list`

### VPC (`vpc.tf` or `main.tf`)

| Old HCL address | New HCL address | Pattern applied |
|---|---|---|
| `google_compute_network.example_main_vpc` | `google_compute_network.vpc` | `vpc-<org>-<purpose>-<env>` via `local.vpc_name` |

### Subnets (`subnets.tf`)

| Old address | New address | New name value |
|---|---|---|
| `module.example-subnets` | `module.subnets` | subnet names → `snet-<org>-<domain>-<env>-<region>` |

### GKE cluster (`gke-private.tf`)

| Old address | New address |
|---|---|
| `module.example-gke-private` | `module.gke_private` |

### Cloud SQL (`cloud-sql-pg.tf`)

| Old address | New address |
|---|---|
| `module.example-cloud-sql-pg` | `module.cloud_sql_pg` |

### Artifact Registry (`artifact-registry.tf`)

| Old address | New address |
|---|---|
| `module.example-artifact-registry` | `module.artifact_registry` |

### Firewall rules (`firewall.tf` or `firewall-rules.tf`)

Resource names change from `example-fw-*` to `fwr-<action>-<src>-to-<dst>-<service>`.
Module rename:

| Old address | New address |
|---|---|
| `module.example-firewall` | `module.firewall` |

---

## Verification Steps

Run these **before** applying renames (capture baseline):

```bash
terraform -chdir=stacks/example state list > /tmp/state-before.txt
```

Apply renames via `moved {}` blocks or CLI:

```bash
# If using moved {} blocks — just plan/apply normally
terraform -chdir=stacks/example plan -no-color

# If using CLI for any resource (fallback):
terraform -chdir=stacks/example state mv \
  'google_compute_network.example_main_vpc' \
  'google_compute_network.vpc'
```

Verify after:

```bash
terraform -chdir=stacks/example state list > /tmp/state-after.txt
diff /tmp/state-before.txt /tmp/state-after.txt

# Plan should show 0 destroy, 0 create for renamed resources
terraform -chdir=stacks/example plan -no-color 2>&1 | grep -E "^Plan:"
# Expected: Plan: 0 to add, 0 to change, 0 to destroy.
```

---

## Acceptance Criterion

`terraform plan` in `stacks/example/` after all renames shows:

```
Plan: 0 to add, 0 to change, 0 to destroy.
```

(Excluding any intentional additions from other tasks in this feature.)
