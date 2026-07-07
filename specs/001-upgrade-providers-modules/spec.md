# Feature Specification: Upgrade Terraform Providers and Modules

**Feature Branch**: `001-upgrade-providers-modules`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "I need to upgrade current project to latest version for the terraform IaC providers, modules, and other."

## Clarifications

### Session 2026-07-07

- Q: For kubernetes (latest 3.2.1) and helm (latest 3.2.0), which are major-version jumps from the pinned 2.32.0/2.15.0, should we upgrade to v3 or stay on v2? → A: Upgrade to `~> 3.2` for both; breaking HCL changes fixed as part of this task; validate availability via floci local services stack.
- Q: The GKE kubernetes-engine module is at v44.3.0 (actual latest, requires google ≥ 7.10) vs the originally estimated ~33.0 — which version should we target? → A: Target `~> 44.0` (true latest); google `>= 7.10` floor is satisfied by the 7.x provider upgrade.
- Q: Terraform minimum version floor — `>= 1.9` (test framework sufficient) or `>= 1.15` (absolute latest stable 1.15.7)? → A: `>= 1.12` — not too old, not too restrictive for contributors or CI pipelines.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Provider Versions Across All Modules (Priority: P1)

As an infrastructure engineer, I need all `versions.tf` files across `modules/`,
`stacks/`, and `examples/` to declare consistent, up-to-date version constraints for
the Google, Google-Beta, Kubernetes, Helm, HTTP, Random, and Null providers so that
`terraform init` succeeds without version-conflict warnings and no module uses a
provider constraint below the project minimum.

**Why this priority**: Version inconsistencies are the root cause of silent behavior
differences between modules and are a blocking issue before any new module can be
added. Some modules still declare `required_version = ">= 0.13"` which is more than
3 major Terraform versions behind.

**Independent Test**: After changes, running `terraform init` in every module, stack,
and example directory succeeds with zero version-conflict warnings. A reviewer can
verify each `versions.tf` uses the same minimum Terraform version (`>= 1.12`) and the
same minimum Google provider version (`>= 7.10`).

**Acceptance Scenarios**:

1. **Given** all `versions.tf` files are updated, **When** `terraform init` is run in
   `modules/networks/vpc/`, **Then** it completes successfully with no warnings about
   provider version conflicts.
2. **Given** all `versions.tf` files are updated, **When** `terraform init` is run in
   `stacks/example/`, **Then** it completes successfully and the lock file reflects the
   same provider version resolution as in the individual modules.
3. **Given** any module's `versions.tf`, **When** it is read, **Then** the Terraform
   `required_version` constraint is `>= 1.12` across all modules (unified minimum).
4. **Given** any module's `versions.tf`, **When** it is read, **Then** the minimum
   Google provider version is `>= 7.10` across all modules (no module has a lower
   minimum than the project-wide floor).

---

### User Story 2 - Update Pinned Provider Versions in Stack (Priority: P2)

As an infrastructure engineer, I need `stacks/example/versions.tf` to use range-based
version constraints (not exact pins) for the Kubernetes, Helm, and HTTP providers, and
to adopt the latest major versions (kubernetes 3.x, helm 3.x) so that security patch
releases can be applied without a code change and the stack is on current provider
generations.

**Why this priority**: Exact-pinned provider versions (`kubernetes = 2.32.0`,
`helm = 2.15.0`, `http = 3.4.5`) prevent adoption of patch releases that may include
security fixes. Additionally, both kubernetes and helm have released major version 3.x
with significant improvements; staying on 2.x means missing active development.

**Independent Test**: `stacks/example/versions.tf` uses `~> 3.2` for kubernetes and
helm and `~> 3.6` for http. All breaking HCL changes introduced by kubernetes 3.x and
helm 3.x are fixed. The floci local services stack confirms kubernetes and helm
providers initialise and plan correctly against local emulated endpoints.

**Acceptance Scenarios**:

1. **Given** updated `stacks/example/versions.tf`, **When** read, **Then** the
   Kubernetes, Helm, and HTTP providers are declared with `~> X.Y` constraints, not
   exact pins, and kubernetes/helm are on `~> 3.2`.
2. **Given** updated constraints, **When** `terraform init` is run, **Then** it
   resolves to `kubernetes 3.2.x` and `helm 3.2.x` or higher within the 3.x series.
3. **Given** the floci services stack is running, **When** `terraform validate` is run
   in `stacks/example/`, **Then** it exits 0 with no deprecated-attribute errors from
   the kubernetes or helm provider 3.x upgrade.

---

### User Story 3 - Unified Upper-Bound Strategy for Google Provider (Priority: P3)

As an infrastructure engineer, I need all `versions.tf` files that reference the
Google or Google-Beta provider to declare an explicit, consistent version constraint
of `>= 7.10, < 8` so that the project is on the latest stable 7.x series and the
upper bound explicitly guards against accidental adoption of a future breaking 8.x
release.

**Why this priority**: The current project has `< 7` as the upper bound, but the
google provider is now at 7.39.0 — meaning the project is behind the latest major
version. Some modules also have no lower bound. A `>= 7.10, < 8` floor+ceiling
ensures all modules use the GKE-module-compatible google version and are protected
against future 8.x breaks.

**Independent Test**: Every `versions.tf` in the project that references
`hashicorp/google` or `hashicorp/google-beta` declares `version = ">= 7.10, < 8"`,
with no file using a floor below `7.10` or omitting the `< 8` upper bound.

**Acceptance Scenarios**:

1. **Given** all `versions.tf` files are updated, **When** each file is read, **Then**
   `hashicorp/google` and `hashicorp/google-beta` both declare `>= 7.10, < 8`.
2. **Given** any file's google constraint, **When** compared to the project floor,
   **Then** no file uses a minimum below `7.10` or omits the `< 8` upper bound.

---

### User Story 4 - Update GKE Module Version Reference (Priority: P3)

As an infrastructure engineer, I need `stacks/example/gke-private.tf` to reference
`~> 44.0` of the `terraform-google-modules/kubernetes-engine` module (v44.3.0 is the
current latest, released 2026-07-06) so that the GKE cluster benefits from 12+ months
of upstream fixes and feature support unavailable in the currently pinned `~> 32.0`.

**Why this priority**: The GKE module is 12 major releases behind. v44.x requires
`google >= 7.10`, which is satisfied by the google 7.x upgrade in US3. The v32→v44
jump includes deprecation removals (such as `network_policy`) that must be addressed.
Availability of the updated module must be confirmed via the floci services stack.

**Independent Test**: `gke-private.tf` references `version = "~> 44.0"`.
`terraform init` resolves `terraform-google-modules/kubernetes-engine ~> 44.0`.
`terraform validate` passes with no deprecated-attribute errors. The floci
integration test confirms the plan completes successfully.

**Acceptance Scenarios**:

1. **Given** `gke-private.tf` is updated, **When** `terraform init` runs, **Then** the
   kubernetes-engine module resolves to `44.x` with no errors.
2. **Given** the updated module version, **When** `terraform validate` runs, **Then**
   there are no errors related to deprecated attributes or removed variables from the
   v32→v44 upgrade.
3. **Given** the floci services stack is running, **When** the integration test runs,
   **Then** `terraform plan` against the emulated stack exits 0 with no errors.

---

### Edge Cases

- What happens when a module's minimum provider version is set higher than the stack's
  minimum? The stack constraint must match or exceed `>= 7.10` to avoid resolution
  conflicts with the GKE v44.x module dependency.
- What if the GKE module v32→v44 jump introduces breaking variable or output changes
  beyond `network_policy`? All breaking changes must be identified and fixed before
  `terraform validate` passes; the task is not done until validate exits 0.
- What happens with the `.terraform.lock.hcl` file in `stacks/example/` after provider
  updates? It must be regenerated (`terraform init -upgrade`) and committed so the new
  resolved versions are locked.
- What if kubernetes 3.x or helm 3.x introduce HCL attribute renames in
  `stacks/example/`? Breaking changes must be identified using release notes and fixed;
  the floci services stack validates the fixed resources plan without errors.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All `versions.tf` files across `modules/`, `stacks/`, and `examples/`
  MUST declare `required_version = ">= 1.12"` (unified Terraform minimum; no file may
  use `>= 0.13`, `>= 0.13.0`, or `>= 1.3`).
- **FR-002**: All `versions.tf` files that reference `hashicorp/google` MUST declare
  `version = ">= 7.10, < 8"` — floor required by GKE module v44.x; upper bound guards
  against breaking 8.x adoption.
- **FR-003**: All `versions.tf` files that reference `hashicorp/google-beta` MUST
  declare `version = ">= 7.10, < 8"` (identical to the google constraint).
- **FR-004**: `stacks/example/versions.tf` MUST declare kubernetes `~> 3.2`, helm
  `~> 3.2`, and http `~> 3.6` (range constraints, not exact pins). All breaking HCL
  attribute changes introduced by kubernetes 3.x and helm 3.x MUST be fixed in the
  corresponding stack `.tf` files.
- **FR-005**: All `versions.tf` files that reference `hashicorp/random` MUST use
  `~> 3.9`. All files that reference `hashicorp/null` MUST use `~> 3.3`.
- **FR-006**: `stacks/example/gke-private.tf` MUST reference
  `terraform-google-modules/kubernetes-engine` at `version = "~> 44.0"` (v44.3.0 is
  current latest as of 2026-07-07).
- **FR-007**: The `.terraform.lock.hcl` file in `stacks/example/` MUST be regenerated
  via `terraform init -upgrade` after all version changes and committed to version
  control.
- **FR-008**: All `terraform fmt`, `tflint`, and `terraform-docs` pre-commit hooks MUST
  pass after all changes.
- **FR-009**: `terraform validate` MUST pass in `stacks/example/` and every example
  directory after all changes.
- **FR-010**: All breaking HCL changes introduced by the kubernetes provider 3.x and
  helm provider 3.x upgrades MUST be identified (via provider release notes) and fixed
  in `stacks/example/` before marking US2 complete.
- **FR-011**: Availability of the updated kubernetes, helm, and GKE module configurations
  MUST be validated using the floci local services stack (docker-compose emulator) before
  marking the respective user stories complete.

### Key Entities

- **Module `versions.tf`**: Declares `required_version` (Terraform) and
  `required_providers` (provider name, source, version constraint). One per module
  directory. Target: `required_version = ">= 1.12"`.
- **Stack `versions.tf`**: Same structure as module `versions.tf` but also includes the
  `backend {}` block. Covers the full set of providers needed by the composed stack.
- **`.terraform.lock.hcl`**: Records the exact resolved provider versions and their
  checksums. Must be regenerated and committed after any provider version constraint
  change.
- **GKE module reference**: The `version` attribute inside a `module` block in a stack
  `.tf` file pointing to the Terraform Registry. Target: `~> 44.0`.
- **Floci services stack**: The docker-compose local GCP emulator stack used to validate
  availability of updated provider and module configurations without real GCP credentials.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `terraform init` in every module directory, every stack directory,
  and every example directory completes without version-conflict warnings or errors.
- **SC-002**: A grep across all `versions.tf` files returns zero instances of
  `required_version` values below `>= 1.12` (e.g., no `>= 0.13`, `>= 1.3`).
- **SC-003**: A grep across all `versions.tf` files confirms every `hashicorp/google`
  and `hashicorp/google-beta` entry declares exactly `>= 7.10, < 8`.
- **SC-004**: `terraform validate` passes in `stacks/example/` with exit code 0 and
  zero error messages; kubernetes and helm provider versions resolve to 3.x.
- **SC-005**: All pre-commit hooks (`terraform-fmt`, `tflint`, `terraform-docs-go`) pass
  with zero errors after changes.
- **SC-006**: The committed `.terraform.lock.hcl` reflects the updated provider versions
  (kubernetes 3.x, helm 3.x, google 7.x); no hash entry corresponds to the old pinned
  versions (kubernetes 2.32.0, helm 2.15.0, http 3.4.5).
- **SC-007**: The floci services stack integration test exits 0, confirming the updated
  kubernetes, helm, and GKE module configurations plan successfully against local
  emulated endpoints.

## Assumptions

- **Terraform**: Latest stable is 1.15.7; minimum floor set to `>= 1.12` (provides
  native test framework and modern HCL features without over-constraining CI).
- **Google provider**: Latest stable is 7.39.0; project floor set to `>= 7.10` (hard
  requirement of the GKE kubernetes-engine module v44.x); upper bound `< 8`.
- **Google-Beta provider**: Tracks the same version as google (7.39.0); same constraints.
- **Kubernetes provider**: Latest stable is 3.2.1; upgrading from pinned 2.32.0 to
  `~> 3.2`; breaking HCL changes must be identified and fixed during implementation.
- **Helm provider**: Latest stable is 3.2.0; upgrading from pinned 2.15.0 to `~> 3.2`;
  breaking HCL changes must be identified and fixed during implementation.
- **HTTP provider**: Latest stable is 3.6.0; upgrading from pinned 3.4.5 to `~> 3.6`.
- **Random provider**: Latest stable is 3.9.0; unified to `~> 3.9` across all modules.
- **Null provider**: Latest stable is 3.3.0; updated to `~> 3.3`.
- **GKE kubernetes-engine module**: Latest stable is v44.3.0 (released 2026-07-06);
  upgrading from `~> 32.0` to `~> 44.0`; requires google `>= 7.10`.
- `stacks/example/` is the only non-example stack in the repository.
- Hardcoded credentials in `stacks/example/cloud-sql-pg.tf` (`user_password`,
  `root_password`) are known test values in the example environment and are out of
  scope for this upgrade (tracked separately).
- The floci services stack (docker-compose local GCP emulator) is the validation
  mechanism for kubernetes, helm, and GKE module availability; real GCP credentials
  are not required for this validation.
- `terraform init -upgrade` will be run in `stacks/example/` to regenerate the lock
  file; no other stacks have lock files to regenerate.
