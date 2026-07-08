# Research: Terraform Provider & Module Upgrade

**Feature**: 001-upgrade-providers-modules
**Date**: 2026-07-07
**Updated**: 2026-07-08 (added section 6 — naming convention and label policy from US5 clarification)

---

## 1. Provider Version Targets

### Decision: Minimum Terraform version → `>= 1.12`

**Rationale**: Terraform 1.12 is a stable release that provides the native test
framework (`.tftest.hcl`, `mock_provider`), `var` references in check blocks, and
modern HCL features used in this upgrade. Setting `>= 1.12` standardizes all modules
without over-constraining contributor or CI environments. The absolute latest stable
is 1.15.7 as of 2026-07-07; `>= 1.12` avoids requiring every team member to update
while capturing all required framework features.

**Alternatives considered**:
- `>= 1.9`: Unlocks the test framework but is 6 minor versions behind; user preferred
  a slightly more recent floor (clarification answer: C — not too old, not too high).
- `>= 1.15`: The absolute latest at time of writing; too restrictive for CI pipelines
  that may lag by a few minor versions.
- `>= 1.3`: Current minimum in some modules — too old; mock provider syntax unavailable.

---

### Decision: Google / Google-Beta provider → `>= 7.10, < 8`

**Rationale**: The GKE `terraform-google-modules/kubernetes-engine` module v44.x
(the current latest) declares a hard `required_providers` minimum of `google >= 7.10`.
This constraint is the binding floor for the entire project. Version 7.x is the
current stable major for `hashicorp/google` (latest: 7.39.0 as of 2026-07-07).
The `< 8` upper bound explicitly guards against accidental adoption of a future
breaking 8.x release.

**Alternatives considered**:
- `>= 6.0, < 7` (original estimate): Incompatible with GKE module v44.x which
  requires `>= 7.10`. Rejected once actual upstream module was confirmed.
- `>= 7.0, < 8`: Lower floor would work but `>= 7.10` is the documented minimum for
  the GKE module v44.x; using the same floor removes ambiguity.
- `>= 7.39, < 8` (exact latest): Too restrictive for team members or CI that may use
  any 7.x release.

**Modules impacted** (current vs. target minimum):

| Module | Current minimum | Target minimum | Notes |
|---|---|---|---|
| networks/firewall-rules | `>= 3.33` | `>= 7.10` | Major uplift |
| networks/routes | `>= 3.83` | `>= 7.10` | Major uplift |
| networks/subnets | `>= 4.25` | `>= 7.10` | Major uplift |
| networks/router-nat | `>= 4.51` | `>= 7.10` | Major uplift |
| networks/vpc | `>= 4.64` | `>= 7.10` | Uplift |
| networks/vpn-ha | `>= 4.64` | `>= 7.10` | Uplift |
| networks/vpn-classic | `< 7` only | `>= 7.10, < 8` | Add lower bound + new upper |
| examples/ha-vpn | `< 7` only | `>= 7.10, < 8` | Add lower bound + new upper |
| sql/postgresql | `>= 5.25` | `>= 7.10` | Uplift |
| workload/artifact-registry | `>= 5.26` | `>= 7.10` | Uplift |
| stacks/example | `< 7` only | `>= 7.10, < 8` | Add lower bound + new upper |

---

### Decision: Random provider → `~> 3.9`

**Rationale**: The 3.x series is stable. Version 3.9.0 is the actual latest stable
release as of 2026-07-07 (verified on GitHub releases). Standardizing all three
modules that use `random` (`router-nat`, `vpn-classic`, `vpn-ha`) eliminates the
current mix of `~> 3.0` / `~> 3.1` / `~> 3.4`.

**Modules impacted**:
- `networks/router-nat`: `~> 3.0` → `~> 3.9`
- `networks/vpn-classic`: `~> 3.4` → `~> 3.9`
- `networks/vpn-ha`: `~> 3.4` → `~> 3.9`
- `modules/sql/postgresql`: `~> 3.x` → `~> 3.9`

---

### Decision: Null provider → `~> 3.3`

**Rationale**: 3.3.0 is the actual latest stable release as of 2026-07-07 (verified
on GitHub releases). Only used in `sql/postgresql`.

---

### Decision: Kubernetes provider → `~> 3.2`

**Rationale**: The kubernetes provider reached v3.2.1 (latest as of 2026-07-07).
This is a major version jump from the pinned 2.32.0. Upgrading to `~> 3.2` allows
patch releases without code changes and aligns with current active development.
Breaking HCL changes introduced by the 3.x series MUST be identified (via release
notes) and fixed in `stacks/example/kube-infra.tf` and `example-app.tf` before
marking this upgrade complete (FR-010).

**Alternatives considered**:
- `~> 2.33` (original estimate): Stays on the 2.x series but misses 3.x improvements
  and is not the active development branch. Rejected per clarification (user chose
  upgrade to v3; validate availability via floci services).

---

### Decision: Helm provider → `~> 3.2`

**Rationale**: The helm provider reached v3.2.0 (latest as of 2026-07-07). This is a
major version jump from the pinned 2.15.0. Breaking HCL changes from helm 3.x MUST be
identified and fixed in `stacks/example/kube-infra.tf` (FR-010).

**Alternatives considered**:
- `~> 2.16` (original estimate): Stays on 2.x; not the active branch. Rejected per
  same clarification answer as kubernetes.

---

### Decision: HTTP provider → `~> 3.6`

**Rationale**: 3.6.0 is the actual latest stable release as of 2026-07-07 (verified
on GitHub releases). Replaces exact pin `3.4.5` with a patch-compatible range.

---

## 2. Upstream Module Version Targets

### Decision: GKE kubernetes-engine module → `~> 44.0`

**Rationale**: The `terraform-google-modules/kubernetes-engine` module v44.3.0 is the
actual current latest release (released 2026-07-06, verified on GitHub). This is a
substantial jump from the current `~> 32.0` pin (+12 major versions). v44.x requires
`google >= 7.10`, which is satisfied by the google provider floor upgrade in this same
feature. The `~> 44.0` constraint pins to the 44.x series, allowing patch updates
while guarding against a 45.x breaking change.

**Breaking changes in v32→v44 to verify** (requires reading upstream release notes):
- The `network_policy` variable was deprecated in v33 and may be removed in later
  versions — verify and remove from `gke-private.tf`.
- `kubernetes_version` behavior with `release_channel = "STABLE"` — confirm
  `gke_freeze_version` local is still valid or should be removed for v44.
- Any additional variables removed or renamed in v33–v44 range must be fixed.

**Alternatives considered**:
- Stay on `~> 32.0`: Incompatible with google `>= 7.10` floor; missing 2+ years of
  upstream GKE feature support and bug fixes.
- `~> 33.0` (original estimate): Not the actual latest; user confirmed target `~> 44.0`
  after search of actual GitHub releases.

---

## 3. Terraform Testing Framework

### Decision: Use Terraform 1.12 built-in test framework (`.tftest.hcl`) for unit tests

**Rationale**: Terraform `>= 1.7` ships a native test runner (`terraform test`) that
supports mock providers. Since we are already upgrading to `>= 1.12`, using the built-in
framework avoids introducing external Go/Ruby dependencies (Terratest, Kitchen-Terraform)
for module-level validation.

**Test types**:

| Test type | Tool | Scope |
|---|---|---|
| **Mock unit tests** | `terraform test` (`.tftest.hcl` + `mock_provider`) | Validates variable/output contracts of each module without real GCP calls |
| **Local integration tests** | `terraform test` + docker-compose GCP stack | Validates plan/apply against local GCP emulator APIs |
| **Static analysis** | `tflint`, `terraform validate`, pre-commit | Already in place |

---

## 4. Local GCP Emulator Stack (docker-compose)

### Decision: docker-compose stack with per-service GCP emulators

**Rationale**: Running Terraform `apply` against real GCP requires credentials and
incurs costs. A local emulator stack intercepts the provider HTTP calls and simulates
GCP API responses, enabling integration tests in CI without GCP credentials.

**Service mapping**:

| GCP Service used in project | Local emulator | Docker image |
|---|---|---|
| Cloud Storage (GCS backend state) | fake-gcs-server | `fsouza/fake-gcs-server:1.49` |
| Compute (VPC, subnets, firewall) | `google-cloud-sdk` pubsub/compute emulators | Not available via emulator — use mock provider |
| Cloud SQL / PostgreSQL | Real PostgreSQL | `postgres:16-alpine` |
| Artifact Registry | Local Docker registry | `registry:2` |
| GKE | Not emulatable locally | Mock provider only |

**Note on GCP Compute/VPC/GKE**: These GCP APIs do not have official local emulators.
Integration tests for network modules (`vpc`, `subnets`, `firewall-rules`, `routes`,
`router-nat`) MUST use mock providers in `.tftest.hcl` files. Only Cloud SQL and
GCS-backed state benefit from docker-compose emulators.

**docker-compose stack structure**:

```yaml
services:
  fake-gcs:          # Simulates GCS for Terraform state backend
  postgres:          # Simulates Cloud SQL PostgreSQL locally
  local-registry:    # Simulates Artifact Registry for Docker images
```

The Terraform `google` provider supports `STORAGE_EMULATOR_HOST` environment variable
to redirect GCS calls to `fake-gcs-server`.

---

## 5. `provider_meta` / `module_name` Update Strategy

### Decision: Update `module_name` in `provider_meta` to reflect the post-upgrade version

Each `versions.tf` carries a `provider_meta "google"` block with a `module_name`
string that identifies the upstream Google module version. After upgrading the
upstream module versions, these strings must also be updated.

**Current → target mapping**:

| Module | Current module_name suffix | Target suffix |
|---|---|---|
| networks/* | `terraform-google-network/v9.1.0` | `terraform-google-network/v9.4.0` (latest) |
| networks/router-nat | `terraform-google-cloud-nat/v5.2.0` | `terraform-google-cloud-nat/v6.0.0` |
| networks/vpn-classic, vpn-ha | `terraform-google-vpn/v4.0.1` | `terraform-google-vpn/v4.2.0` |
| sql/postgresql | `terraform-google-sql-db:postgresql/v22.0.0` | `terraform-google-sql-db:postgresql/v23.0.0` |
| workload/artifact-registry | `artifact-registry/v0.2.0` | `artifact-registry/v0.3.0` |

*Note: Exact versions should be verified against the GitHub releases at implementation
time. The values above are best estimates based on known release cadence.*

---

## 6. GCP Resource Naming Convention & Label Policy (US5)

*Added 2026-07-08 following clarification session.*

### Decision: All naming tokens are Terraform variables (no hardcoded org/env strings)

**Rationale**: Modules must be reusable across organisations and environments without
code changes. Embedding an org token (e.g. `obk`) into a resource name in HCL means
every fork of the module must find-and-replace the org string. Variable-driven tokens
let the caller supply context at `terraform apply` time via `tfvars`.

**Alternatives considered**:
- Hardcode `obk` as the org token everywhere: Simple but prevents multi-org reuse;
  rejected per user clarification (2026-07-08).
- Use a `locals {}` org constant per stack: Slightly better but still requires code
  change per org; rejected in favour of a `var.org` input.

---

### Decision: `common_labels` at stack level; modules accept a `labels` input variable

**Rationale**: Defining `common_labels` once per stack ensures label consistency
without duplicating the 10-key map inside each module. Modules stay thin — they
receive `var.labels` and merge it: `labels = merge(var.labels, { component = "vpc" })`.
This pattern lets the stack override or extend labels without touching module internals.

**`common_labels` structure** (all values from stack variables except constants):

```hcl
locals {
  common_labels = {
    org          = var.org           # e.g. "obk"
    landing_zone = "gcp_lz"         # constant
    env          = var.env           # shd | prd | np | sbx
    domain       = var.domain        # platform | connectivity | data | ml | sandbox
    app          = var.app           # workload identifier
    component    = var.component     # vpc | subnet | bq | gcs | dataproc | vertex
    owner_team   = var.owner_team    # netops | secops | data_platform | ml_platform
    cost_center  = var.cost_center   # free-form billing code
    managed_by   = "terraform"       # constant — never a variable
    data_class   = var.data_class    # public | internal | confidential | restricted | na
  }
}
```

**Alternatives considered**:
- Each module defines its own `common_labels` internal local: Labels would differ
  between modules if the caller forgets to align values. Rejected.
- No module `labels` variable, caller sets labels via `provider_default_labels`:
  Provider-level default labels are a GCP feature, not supported by all resource types;
  module-level `labels` argument is the portable approach.

---

### Decision: Validate `env` and `data_class` only; other tokens are free-form

**Rationale**: `env` and `data_class` are high-stakes enumerations — wrong values
cause cost misattribution (`env`) or compliance failures (`data_class`). The other
tokens (`domain`, `owner_team`, `app`, `component`) are team-defined strings that
vary per project and would require constant maintenance of the validation allowlist.

**Validated enumerations**:

| Variable | Allowed values |
|---|---|
| `env` | `shd`, `prd`, `np`, `sbx` |
| `data_class` | `public`, `internal`, `confidential`, `restricted`, `na` |

**Implementation**: `validation {}` block inside each stack's `variables.tf`:

```hcl
variable "env" {
  type        = string
  description = "Deployment environment. Controls resource naming and label value."
  validation {
    condition     = contains(["shd", "prd", "np", "sbx"], var.env)
    error_message = "env must be one of: shd, prd, np, sbx."
  }
}
```

---

### Decision: `terraform state mv` for all resource renames; document sequences in contracts

**Rationale**: Renaming a Terraform resource block (e.g. `google_compute_network.main`
→ `google_compute_network.vpc`) without a corresponding `terraform state mv` causes
Terraform to plan destroy+create, which in a real environment deletes the resource.
In `stacks/example/` this is acceptable for non-persistent resources, but documenting
the state mv sequence in `contracts/state-migration.md` enables zero-destruction renames
for any team that has applied the stack.

**State mv pattern**:
```bash
terraform state mv \
  'google_compute_network.example_main_vpc' \
  'google_compute_network.vpc'
```

**Alternatives considered**:
- `moved {}` blocks in HCL (Terraform 1.1+): Cleaner than CLI commands and
  self-documenting in code. Will be used where the resource type supports it.
  `terraform state mv` is the fallback for resource types that don't support `moved {}`.

---

### Naming pattern reference

Full 30-resource-type table documented in `contracts/naming-policy.md`.

**Key patterns for resources present in this project**:

| Resource in project | Pattern | Example (example stack) |
|---|---|---|
| VPC | `vpc-<org>-<purpose>-<env>` | `vpc-obk-main-example` |
| Subnet | `snet-<org>-<domain>-<env>-<region>` | `snet-obk-platform-example-th` |
| Cloud NAT | `nat-<org>-<domain>-<purpose>-<env>-<region>-nn` | `nat-obk-con-egress-example-th-01` |
| Cloud Router | `cr-<org>-<domain>-<purpose>-<env>-<region>-nn` | `cr-obk-con-nat-example-th-01` |
| HA VPN Gateway | `havgw-<org>-<peer>-<env>-<region>-nn` | `havgw-obk-onprem-example-th-01` |
| VPN Tunnel | `vpntun-<org>-<peer>-<env>-<region>-a/b` | `vpntun-obk-onprem-example-th-a` |
| Firewall rule | `fwr-<action>-<src>-to-<dst>-<service>` | `fwr-allow-platform-example-to-gke-443` |
| Artifact Registry | `ar-<org>-<domain>-<artifact>-<env>-<region>` | `ar-obk-platform-docker-example-sg` |
| Cloud SQL instance | `sql-<org>-<domain>-<engine>-<env>-<region>` | `sql-obk-platform-pg-example-sg` |
