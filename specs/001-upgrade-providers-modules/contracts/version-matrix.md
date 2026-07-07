# Contract: Provider Version Matrix

**Feature**: 001-upgrade-providers-modules
**Date**: 2026-07-07
**Updated**: 2026-07-07 (post-clarification — all targets revised to match upstream GitHub repositories)

This document is the authoritative reference for all provider version constraints
after the upgrade. Every `versions.tf` file MUST comply with this matrix.

---

## Terraform Core

| Constraint | Applied to |
|---|---|
| `>= 1.12` | All `versions.tf` files — modules, stacks, examples |

---

## Provider Constraints

### hashicorp/google

```hcl
google = {
  source  = "hashicorp/google"
  version = ">= 7.10, < 8"
}
```

Applied to all `versions.tf` files that reference this provider.
Floor `7.10` is required by `terraform-google-modules/kubernetes-engine ~> 44.0`.

### hashicorp/google-beta

```hcl
google-beta = {
  source  = "hashicorp/google-beta"
  version = ">= 7.10, < 8"
}
```

Applied to: `modules/networks/vpc`, `modules/networks/vpn-ha`, `modules/sql/postgresql`,
`modules/workload/artifact-registry`, `examples/ha-vpn`, `stacks/example`.

### hashicorp/random

```hcl
random = {
  source  = "hashicorp/random"
  version = "~> 3.9"
}
```

Applied to: `modules/networks/router-nat`, `modules/networks/vpn-classic`,
`modules/networks/vpn-ha`, `modules/sql/postgresql`.

### hashicorp/null

```hcl
null = {
  source  = "hashicorp/null"
  version = "~> 3.3"
}
```

Applied to: `modules/sql/postgresql`.

### hashicorp/kubernetes

```hcl
kubernetes = {
  source  = "hashicorp/kubernetes"
  version = "~> 3.2"
}
```

Applied to: `stacks/example` only.
Breaking HCL changes from 3.x MUST be fixed in `stacks/example/kube-infra.tf` and
`stacks/example/example-app.tf` before this constraint is deployed (FR-010).

### hashicorp/helm

```hcl
helm = {
  source  = "hashicorp/helm"
  version = "~> 3.2"
}
```

Applied to: `stacks/example` only.
Breaking HCL changes from 3.x MUST be fixed in `stacks/example/kube-infra.tf` before
this constraint is deployed (FR-010).

### hashicorp/http

```hcl
http = {
  source  = "hashicorp/http"
  version = "~> 3.6"
}
```

Applied to: `stacks/example` only.

---

## Module Version References

### GKE private-cluster module (in stacks/example/gke-private.tf)

```hcl
module "example-gke-private" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 44.0"
  ...
}
```

Requires `google >= 7.10` — satisfied by the `>= 7.10, < 8` floor in this matrix.

---

## File-by-File Compliance Checklist

| File | required_version | google | google-beta | random | null | kubernetes | helm | http |
|---|---|---|---|---|---|---|---|---|
| `modules/networks/firewall-rules/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | — | — | — | — | — | — |
| `modules/networks/routes/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | — | — | — | — | — | — |
| `modules/networks/subnets/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | — | — | — | — | — | — |
| `modules/networks/router-nat/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | — | `~> 3.9` | — | — | — | — |
| `modules/networks/vpc/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | `>= 7.10, < 8` | — | — | — | — | — |
| `modules/networks/vpn-classic/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | — | `~> 3.9` | — | — | — | — |
| `modules/networks/vpn-ha/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | `>= 7.10, < 8` | `~> 3.9` | — | — | — | — |
| `modules/sql/postgresql/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | `>= 7.10, < 8` | `~> 3.9` | `~> 3.3` | — | — | — |
| `modules/workload/artifact-registry/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | `>= 7.10, < 8` | — | — | — | — | — |
| `examples/ha-vpn/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | `>= 7.10, < 8` | — | — | — | — | — |
| `stacks/example/versions.tf` | `>= 1.12` | `>= 7.10, < 8` | `>= 7.10, < 8` | — | — | `~> 3.2` | `~> 3.2` | `~> 3.6` |

---

## Verification Commands

Run these after applying all changes to confirm compliance:

```bash
# Check Terraform required_version across all files — should all show >= 1.12
grep -r "required_version" --include="versions.tf" .

# Check google provider version across all files
grep -r '"hashicorp/google"' --include="versions.tf" -A2 .

# Confirm no legacy required_version constraints remain
grep -r ">= 0\.13\|>= 1\.3\|>= 1\.9\|>= 1\.5" --include="versions.tf" .
# Expected: no output

# Confirm no old < 7 upper bound remains
grep -r '< 7"' --include="versions.tf" .
# Expected: no output

# Confirm no exact-pinned providers remain in stacks/example
grep -E '"[0-9]+\.[0-9]+\.[0-9]+"' stacks/example/versions.tf
# Expected: no output (all should be ranges)

# Confirm kubernetes and helm are on 3.x
grep -r '"hashicorp/kubernetes"' --include="versions.tf" -A2 stacks/
grep -r '"hashicorp/helm"' --include="versions.tf" -A2 stacks/
# Expected: both show ~> 3.2

# Confirm GKE module reference is on 44.x
grep "version" stacks/example/gke-private.tf | grep "kubernetes-engine\|44\."
# Expected: version = "~> 44.0"
```
