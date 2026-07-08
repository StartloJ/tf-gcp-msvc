# Implementation Plan: Upgrade Terraform Providers and Modules

**Branch**: `001-upgrade-providers-modules` | **Date**: 2026-07-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-upgrade-providers-modules/spec.md`

---

## Summary

Upgrade all `versions.tf` files across the repository to use a unified Terraform
minimum of `>= 1.12`, raise all Google provider lower bounds to `>= 7.10, < 8`
(required by GKE kubernetes-engine module v44.x), standardize ancillary providers
(random `~> 3.9`, null `~> 3.3`, kubernetes `~> 3.2`, helm `~> 3.2`, http `~> 3.6`),
update the upstream GKE module from `~> 32.0` to `~> 44.0`, fix all kubernetes 3.x
and helm 3.x breaking HCL changes, and introduce a Terraform 1.12 native test suite
(`.tftest.hcl` mock-provider unit tests per module + a docker-compose local GCP
emulator stack for integration tests).

Additionally, implement the org-wide GCP resource naming convention and label policy
(US5): rename all existing resources in `stacks/example/` to follow variable-driven
patterns (e.g. `vpc-<org>-<purpose>-<env>`, `snet-<org>-<domain>-<env>-<region>`),
add a `common_labels` local to each stack, add a `labels` input variable to every
module, and enforce `env` / `data_class` enum validation in stack `variables.tf`.
State migration via `terraform state mv` is used where possible to avoid resource
destruction.

All changes must pass `terraform validate`, `terraform test`, pre-commit hooks, and
the integration test suite before being marked done.

---

## Technical Context

**Language/Version**: HCL (Terraform 1.12+)

**Primary Dependencies**:
- `hashicorp/google >= 7.10, < 8`
- `hashicorp/google-beta >= 7.10, < 8`
- `hashicorp/random ~> 3.9`
- `hashicorp/null ~> 3.3`
- `hashicorp/kubernetes ~> 3.2` (stack only; breaking HCL changes must be fixed)
- `hashicorp/helm ~> 3.2` (stack only; breaking HCL changes must be fixed)
- `hashicorp/http ~> 3.6` (stack only)
- `terraform-google-modules/kubernetes-engine ~> 44.0` (GKE module; requires google >= 7.10)

**Storage**: GCS (remote state backend in `stacks/example/`)

**Testing**:
- `terraform test` (built-in 1.9 framework, `.tftest.hcl` files, mock providers)
- docker-compose local GCP emulator stack (`fsouza/fake-gcs-server`, `postgres:16-alpine`,
  `registry:2`)
- `tflint`, `terraform validate`, `pre-commit` (static analysis gates, already in place)

**Target Platform**: GCP (Google Cloud Platform) — GKE, Cloud SQL, VPC, VPN, Artifact Registry

**Project Type**: Terraform IaC module library + environment stack

**Performance Goals**: `terraform validate` completes in < 30 s per module; full unit test
suite completes in < 2 min; integration test suite completes in < 5 min on local docker-compose stack

**Constraints**:
- No real GCP credentials required for unit tests or integration tests (emulator stack only)
- `stacks/example/` is the only stack requiring lock file regeneration
- VPC, GKE, VPN modules have no GCP emulator — unit tests use mock providers only
- All pre-commit hooks must remain green throughout

**Scale/Scope**: 11 `versions.tf` files + 1 GKE module reference + 9 new module test dirs
+ 1 integration test dir + 2 test runner scripts + 9 module `labels` variable additions
+ resource renames across `stacks/example/` (via `terraform state mv`) + 1 `locals.tf`
per stack with `common_labels` + 2 stack `validation {}` blocks (`env`, `data_class`)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| **I. Module-First Design** | PASS | Each module is upgraded independently; no cross-module changes |
| **II. Security-First Infrastructure** | PASS | Raising google provider floor removes deprecated security APIs; no IAM regressions |
| **III. State Isolation** | PASS | Lock file updated in `stacks/example/` only; no backend changes |
| **IV. Immutable via Code Review** | PASS | All changes via PR; pre-commit hooks must stay green |
| **V. Simplicity & YAGNI** | PASS | Test files are minimal; no speculative test cases added |
| **VI. Observable & Self-Documenting** | PASS | `terraform-docs` README regenerated for any module with variable/output changes; naming convention and `common_labels` make every resource identifiable without reading state |
| **VII. Think Before Coding** | PASS | research.md resolves all version decisions upfront |
| **VIII. Simplicity First** | PASS | Mock tests use `command = plan` only (no apply); docker-compose uses three minimal services |
| **IX. Surgical Changes** | PASS | Only `versions.tf`, the GKE module version pin, and new test files are touched |
| **X. Goal-Driven Execution** | PASS | Each task has a verifiable check; success = all `terraform test` assertions pass + pre-commit green |

**Complexity Justification**:

| Decision | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| docker-compose emulator stack | Integration tests must run without real GCP credentials | Mock-only tests can't verify provider-level API compatibility; emulators allow at least GCS/SQL path |
| `tests/` dir per module | Terraform 1.9 test runner requires tests co-located with module | Single global test dir is not supported by `terraform test` discovery |
| All naming tokens as variables | Multi-org portability; no org-specific strings committed to modules | Hardcoded org tokens would break any team that forks or reuses modules in a different org |
| Stack-level `common_labels`, module `labels` input | Labels must be consistent across all resources without duplicating keys in each module | Module-internal label construction prevents the stack from overriding or auditing label values |
| `terraform state mv` for renames | Avoid destroy/re-create of example resources that would lose state continuity | Letting TF destroy/re-create forces manual cleanup in any environment where the stack has been applied |

---

## Project Structure

### Documentation (this feature)

```text
specs/001-upgrade-providers-modules/
├── plan.md              # This file
├── research.md          # Phase 0: version decisions and rationale
├── data-model.md        # Phase 1: version matrix entities + test file structure
├── quickstart.md        # Phase 1: end-to-end validation guide
├── contracts/
│   ├── version-matrix.md    # Authoritative provider version constraint matrix
│   └── test-interface.md    # Test entry points and emulator contracts
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root — changes from this feature)

```text
modules/
├── networks/
│   ├── firewall-rules/
│   │   ├── versions.tf            # updated: required_version + google floor
│   │   └── tests/
│   │       └── unit.tftest.hcl    # NEW: mock-provider unit test
│   ├── routes/
│   │   ├── versions.tf
│   │   └── tests/unit.tftest.hcl
│   ├── subnets/
│   │   ├── versions.tf
│   │   └── tests/unit.tftest.hcl
│   ├── router-nat/
│   │   ├── versions.tf            # updated: random ~> 3.9
│   │   └── tests/unit.tftest.hcl
│   ├── vpc/
│   │   ├── versions.tf
│   │   └── tests/unit.tftest.hcl
│   ├── vpn-classic/
│   │   ├── versions.tf            # updated: add google lower bound + random ~> 3.9
│   │   └── tests/unit.tftest.hcl
│   └── vpn-ha/
│       ├── versions.tf            # updated: random ~> 3.9
│       └── tests/unit.tftest.hcl
├── sql/
│   └── postgresql/
│       ├── versions.tf            # updated: null ~> 3.3, random ~> 3.9
│       └── tests/unit.tftest.hcl
└── workload/
    └── artifact-registry/
        ├── versions.tf
        └── tests/unit.tftest.hcl

stacks/
└── example/
    ├── versions.tf                # updated: kubernetes ~> 3.2, helm ~> 3.2, http ~> 3.6
    ├── variables.tf               # updated: add org, domain, env, app, component,
    │                              #   owner_team, cost_center, data_class variables;
    │                              #   validation{} for env and data_class
    ├── locals.tf                  # NEW: common_labels local block (10 keys)
    ├── gke-private.tf             # updated: module version ~> 44.0, remove deprecated attrs
    │                              #   resource name → vpc-<org>-<purpose>-<env> pattern
    ├── *.tf                       # updated: all resource name attrs renamed to new patterns
    ├── .terraform.lock.hcl        # regenerated by terraform init -upgrade
    └── tests/
        ├── unit.tftest.hcl        # NEW: stack-level mock tests (incl. label assertions)
        └── integration.tftest.hcl # NEW: runs against docker-compose emulator stack

stacks/
└── example_vpc_shared/
    ├── variables.tf               # updated: add org, domain, env, app, component,
    │                              #   owner_team, cost_center, data_class + validation{}
    └── locals.tf                  # NEW: common_labels local block

examples/
└── ha-vpn/
    └── versions.tf                # updated: add google lower bound

tests/                             # NEW top-level test support directory
├── local-gcp-stack/
│   ├── docker-compose.yml         # fake-gcs, postgres, local-registry
│   ├── init.sh                    # start stack, health-check, export env vars
│   └── teardown.sh                # stop and remove containers
├── run-unit-tests.sh              # iterate all module test dirs, run terraform test
└── run-integration-tests.sh      # start stack, run integration tftest, teardown
```

**Structure Decision**: Repository-root-level `tests/` directory for shared test support
(docker-compose stack and runner scripts). Module-level `tests/` directories for
`.tftest.hcl` files, which is required by `terraform test` discovery. This avoids
any new top-level module being created (all test infra is tooling, not Terraform modules).

---

## Phase 0: Research Summary

All NEEDS CLARIFICATION items resolved. See [research.md](research.md) for full
rationale. Key decisions:

| Decision | Choice |
|---|---|
| Terraform minimum | `>= 1.12` |
| Google provider floor | `>= 7.10, < 8` |
| Random provider | `~> 3.9` |
| Null provider | `~> 3.3` |
| Kubernetes provider | `~> 3.2` (range, not pin; breaking HCL changes fixed) |
| Helm provider | `~> 3.2` (range, not pin; breaking HCL changes fixed) |
| HTTP provider | `~> 3.6` (range, not pin) |
| GKE module | `~> 44.0` |
| Unit test tool | `terraform test` (built-in, `.tftest.hcl`, mock provider) |
| Integration test tool | docker-compose + `terraform test` against emulators |
| Naming convention | Org-wide variable-driven patterns (e.g. `vpc-<org>-<purpose>-<env>`); all tokens as Terraform variables |
| Label policy | Stack-level `common_labels` local (10 keys); each module accepts `labels = map(string)` |
| Label validation | `env` and `data_class` validated via `validation {}` blocks in stack `variables.tf` |
| Resource rename strategy | `terraform state mv` preferred; destroy/re-create only where state mv is not supported |

---

## Phase 1: Design Summary

See [data-model.md](data-model.md), [contracts/version-matrix.md](contracts/version-matrix.md),
[contracts/test-interface.md](contracts/test-interface.md), and [quickstart.md](quickstart.md).

Key design decisions:

- **Mock provider tests** (`command = plan`, not `apply`) for all 9 modules — validates
  variable/output contracts without real GCP.
- **docker-compose** provides three services: `fake-gcs-server` (GCS), `postgres:16-alpine`
  (Cloud SQL), `registry:2` (Artifact Registry). GKE/VPC/VPN have no emulators — mock only.
- **Test runner scripts** (`run-unit-tests.sh`, `run-integration-tests.sh`) allow CI to
  invoke all tests with a single command.
- **`STORAGE_EMULATOR_HOST`** environment variable routes Terraform GCS backend calls
  to local fake-gcs during integration tests.
- **Naming convention entities** documented in [data-model.md](data-model.md) (Entities 7–8):
  `common_labels` local structure and module `labels` variable contract.
- **`contracts/naming-policy.md`**: Authoritative naming pattern table (30 resource types)
  and `common_labels` key reference — single source of truth for implementors.
- **`terraform state mv` sequences** for each renamed resource in `stacks/example/` are
  documented in [contracts/state-migration.md](contracts/state-migration.md) so the rename
  can be applied atomically without resource destruction.
