---
description: "Task list for terraform provider and module upgrade with local integration tests"
---

# Tasks: Upgrade Terraform Providers and Modules

**Input**: Design documents from `specs/001-upgrade-providers-modules/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**Tests**: Required — every task MUST pass its verification check before being marked done.
Tests (`.tftest.hcl`) are written BEFORE implementation within each user story phase.

**Organization**: Tasks grouped by user story. US1 (P1) can begin after Foundational phase.
US2, US3, US4 can proceed in parallel after US1 is checkpointed (all are independent).

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in same phase)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Every task includes a **Verify** line — the check that MUST pass before marking done

## Target Version Reference (from spec clarifications 2026-07-07)

| Provider / Tool | Constraint |
|---|---|
| Terraform | `>= 1.12` |
| hashicorp/google | `>= 7.10, < 8` |
| hashicorp/google-beta | `>= 7.10, < 8` |
| hashicorp/random | `~> 3.9` |
| hashicorp/null | `~> 3.3` |
| hashicorp/kubernetes | `~> 3.2` |
| hashicorp/helm | `~> 3.2` |
| hashicorp/http | `~> 3.6` |
| GKE kubernetes-engine module | `~> 44.0` |

## Path Conventions

- Modules: `modules/<category>/<name>/`
- Stack: `stacks/example/`
- Examples: `examples/ha-vpn/`
- Tests: `tests/` (top-level, new)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and test runner scaffolding used by all later phases.

- [x] T001 Create top-level test directory structure: `mkdir -p tests/local-gcp-stack` and `mkdir -p` for each module's `tests/` subdirectory
  - **Verify**: `ls tests/local-gcp-stack` and `ls modules/networks/vpc/tests` both succeed

- [x] T002 [P] Create `tests/run-unit-tests.sh` — iterates all 9 module test dirs and runs `terraform test -no-color`; exits non-zero if any module fails
  - **Verify**: `bash -n tests/run-unit-tests.sh` (syntax check) exits 0

- [x] T003 [P] Create `tests/run-integration-tests.sh` — starts docker-compose stack, runs `terraform test` in `stacks/example/tests/` targeting integration file, tears down; exits non-zero on any failure
  - **Verify**: `bash -n tests/run-integration-tests.sh` exits 0

---

## Phase 2: Foundational (Local GCP Emulator Stack)

**Purpose**: Build the docker-compose emulator stack that integration tests depend on.
Must be complete before integration tests in any user story can run.

**⚠️ CRITICAL**: Integration test tasks (T034, T039, T049) depend on this phase completing first.

- [x] T004 Create `tests/local-gcp-stack/docker-compose.yml` with three services: `fake-gcs` (image: `fsouza/fake-gcs-server:1.49`, port 4443), `postgres` (image: `postgres:16-alpine`, port 5432, env POSTGRES_PASSWORD=test), `local-registry` (image: `registry:2`, port 5000)
  - **Verify**: `docker compose -f tests/local-gcp-stack/docker-compose.yml config` exits 0 (valid YAML)

- [x] T005 Create `tests/local-gcp-stack/init.sh` — runs `docker compose up -d`, health-checks each service (curl fake-gcs, pg_isready, curl local-registry), exports env vars (`STORAGE_EMULATOR_HOST`, `CLOUDSDK_CORE_PROJECT=test-project`, `GOOGLE_OAUTH_ACCESS_TOKEN=fake-token`)
  - **Verify**: `bash -n tests/local-gcp-stack/init.sh` exits 0

- [x] T006 Create `tests/local-gcp-stack/teardown.sh` — runs `docker compose -f tests/local-gcp-stack/docker-compose.yml down -v`
  - **Verify**: `bash -n tests/local-gcp-stack/teardown.sh` exits 0

**Checkpoint**: Local GCP emulator stack files ready — integration tests can now reference this stack.

---

## Phase 3: User Story 1 — Consistent Provider Versions Across All Modules (Priority: P1) 🎯 MVP

**Goal**: All 9 module `versions.tf` files use `required_version = ">= 1.12"` and
`hashicorp/google >= 7.10, < 8`. Random provider unified to `~> 3.9`. Null to `~> 3.3`.

**Independent Test**: Run `./tests/run-unit-tests.sh` — all 9 modules report `0 assertions failed`.

### Tests for User Story 1 ⚠️ Write FIRST, run BEFORE and AFTER implementation

> **NOTE: Create test files first. Run them before editing versions.tf to see baseline.
> After version changes, re-run — tests MUST still pass.**

- [x] T007 [P] [US1] Create `modules/networks/firewall-rules/tests/unit.tftest.hcl` — mock_provider "google"; run block with `command = plan`; assert ingress_rules output count equals input list length
  - **Verify**: `terraform -chdir=modules/networks/firewall-rules test` exits 0, `0 assertions failed`

- [x] T008 [P] [US1] Create `modules/networks/routes/tests/unit.tftest.hcl` — mock_provider "google"; assert routes output is not null
  - **Verify**: `terraform -chdir=modules/networks/routes test` exits 0, `0 assertions failed`

- [x] T009 [P] [US1] Create `modules/networks/subnets/tests/unit.tftest.hcl` — mock_provider "google"; assert subnets output length equals input list length
  - **Verify**: `terraform -chdir=modules/networks/subnets test` exits 0, `0 assertions failed`

- [x] T010 [P] [US1] Create `modules/networks/router-nat/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "random"; assert name output is not empty
  - **Verify**: `terraform -chdir=modules/networks/router-nat test` exits 0, `0 assertions failed`

- [x] T011 [P] [US1] Create `modules/networks/vpc/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "google-beta"; assert network_name output equals input network_name variable
  - **Verify**: `terraform -chdir=modules/networks/vpc test` exits 0, `0 assertions failed`

- [x] T012 [P] [US1] Create `modules/networks/vpn-classic/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "random"; assert gateway output is not null
  - **Verify**: `terraform -chdir=modules/networks/vpn-classic test` exits 0, `0 assertions failed`

- [x] T013 [P] [US1] Create `modules/networks/vpn-ha/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "google-beta", mock_provider "random"; assert tunnels output count equals 2 (HA pair)
  - **Verify**: `terraform -chdir=modules/networks/vpn-ha test` exits 0, `0 assertions failed`

- [x] T014 [P] [US1] Create `modules/sql/postgresql/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "google-beta", mock_provider "random", mock_provider "null"; assert instance_name output is not empty
  - **Verify**: `terraform -chdir=modules/sql/postgresql test` exits 0, `0 assertions failed`

- [x] T015 [P] [US1] Create `modules/workload/artifact-registry/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "google-beta"; assert repository_id output equals input variable
  - **Verify**: `terraform -chdir=modules/workload/artifact-registry test` exits 0, `0 assertions failed`

### Implementation for User Story 1

- [x] T016 [P] [US1] Update `modules/networks/firewall-rules/versions.tf` — set `required_version = ">= 1.12"` and google `version = ">= 7.10, < 8"`; update provider_meta module_name to `terraform-google-network:firewall-rules/v9.4.0`
  - **Verify**: `terraform -chdir=modules/networks/firewall-rules validate` exits 0 AND `terraform -chdir=modules/networks/firewall-rules test` exits 0

- [x] T017 [P] [US1] Update `modules/networks/routes/versions.tf` — set `required_version = ">= 1.12"` and google `version = ">= 7.10, < 8"`; update provider_meta to `terraform-google-network:routes/v9.4.0`
  - **Verify**: `terraform -chdir=modules/networks/routes validate` exits 0 AND unit test passes

- [x] T018 [P] [US1] Update `modules/networks/subnets/versions.tf` — set `required_version = ">= 1.12"` and google `version = ">= 7.10, < 8"`; update provider_meta to `terraform-google-network:subnets/v9.4.0`
  - **Verify**: `terraform -chdir=modules/networks/subnets validate` exits 0 AND unit test passes

- [x] T019 [P] [US1] Update `modules/networks/router-nat/versions.tf` — set `required_version = ">= 1.12"`, google `>= 7.10, < 8`, random `~> 3.9`; update provider_meta to `terraform-google-cloud-nat/v6.0.0`
  - **Verify**: `terraform -chdir=modules/networks/router-nat validate` exits 0 AND unit test passes

- [x] T020 [P] [US1] Update `modules/networks/vpc/versions.tf` — set `required_version = ">= 1.12"`, google `>= 7.10, < 8`, google-beta `>= 7.10, < 8`; update both provider_meta to `terraform-google-network:vpc/v9.4.0`
  - **Verify**: `terraform -chdir=modules/networks/vpc validate` exits 0 AND unit test passes

- [x] T021 [P] [US1] Update `modules/networks/vpn-classic/versions.tf` — set `required_version = ">= 1.12"`, google `>= 7.10, < 8`, random `~> 3.9`; update provider_meta to `terraform-google-vpn/v4.2.0`
  - **Verify**: `terraform -chdir=modules/networks/vpn-classic validate` exits 0 AND unit test passes

- [x] T022 [P] [US1] Update `modules/networks/vpn-ha/versions.tf` — set `required_version = ">= 1.12"`, google `>= 7.10, < 8`, google-beta `>= 7.10, < 8`, random `~> 3.9`; update both provider_meta to `terraform-google-vpn/v4.2.0`
  - **Verify**: `terraform -chdir=modules/networks/vpn-ha validate` exits 0 AND unit test passes

- [x] T023 [P] [US1] Update `modules/sql/postgresql/versions.tf` — set `required_version = ">= 1.12"`, null `~> 3.3`, random `~> 3.9`, google `>= 7.10, < 8`, google-beta `>= 7.10, < 8`; update both provider_meta to `terraform-google-sql-db:postgresql/v23.0.0`
  - **Verify**: `terraform -chdir=modules/sql/postgresql validate` exits 0 AND unit test passes

- [x] T024 [P] [US1] Update `modules/workload/artifact-registry/versions.tf` — set `required_version = ">= 1.12"`, google `>= 7.10, < 8`, google-beta `>= 7.10, < 8`; update both provider_meta to `artifact-registry/v0.3.0`
  - **Verify**: `terraform -chdir=modules/workload/artifact-registry validate` exits 0 AND unit test passes

- [x] T025 [US1] Run `./tests/run-unit-tests.sh` — all 9 module unit tests must pass (depends on T007–T024)
  - **Verify**: Script exits 0; output shows `0 assertions failed` for each of the 9 modules

**Checkpoint**: All 9 modules validated with updated constraints and passing unit tests.

---

## Phase 4: User Story 2 — Update Pinned Provider Versions in Stack (Priority: P2)

**Goal**: `stacks/example/versions.tf` replaces exact-pinned kubernetes/helm/http with
`~> 3.2` / `~> 3.2` / `~> 3.6`. Breaking HCL changes from kubernetes 3.x and helm 3.x
identified, fixed, and validated via floci services stack.

**Independent Test**: `terraform -chdir=stacks/example test` passes unit tests.
Lock file reflects kubernetes 3.x and helm 3.x resolved versions (no 2.32.0/2.15.0 hashes).
Floci integration test exits 0 confirming kubernetes and helm resources plan successfully.

### Tests for User Story 2 ⚠️ Write FIRST

- [x] T026 [US2] Create `stacks/example/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "google-beta", mock_provider "kubernetes", mock_provider "helm", mock_provider "http"; assert `google_compute_address.gke_app_lb_ip` plan contains address name from local
  - **Verify**: `terraform -chdir=stacks/example test -test-directory=tests/` exits 0 (mock provider skips real API)

### Breaking-Change Audit (FR-010) ⚠️ Required before HCL edits

- [x] T045 [P] [US2] Read kubernetes provider v3.x migration guide at `github.com/hashicorp/terraform-provider-kubernetes/releases`; document all breaking attribute/resource renames that affect `stacks/example/kube-infra.tf` and `stacks/example/example-app.tf` (e.g., deprecated `v1` resource suffixes, renamed spec fields)
  - **Verify**: A findings list exists (PR description or inline comment) listing every changed attribute name found in the stack files; `grep` run against each identified old attribute name in the stack confirms coverage

- [x] T046 [P] [US2] Read helm provider v3.x migration guide at `github.com/hashicorp/terraform-provider-helm/releases`; document all breaking changes affecting `helm_release` blocks in `stacks/example/kube-infra.tf` (e.g., removed `verify`, `lint` attributes or changed set block syntax)
  - **Verify**: Findings documented; all affected attributes in `kube-infra.tf` identified before any HCL edits are made

### HCL Breaking-Change Fixes (FR-010)

- [x] T047 [US2] Apply kubernetes 3.x HCL fixes in `stacks/example/kube-infra.tf` and `stacks/example/example-app.tf` based on T045 audit — update renamed resources, remove removed attributes, fix changed block structures
  - **Verify**: `terraform -chdir=stacks/example validate` exits 0; `grep` for each deprecated attribute name (documented in T045) returns empty in both files

- [x] T048 [US2] Apply helm 3.x HCL fixes in `stacks/example/kube-infra.tf` based on T046 audit — update helm_release attributes and block structures for 3.x compatibility
  - **Verify**: `terraform -chdir=stacks/example validate` exits 0; `grep` for each deprecated helm attribute (documented in T046) returns empty in `kube-infra.tf`

### Implementation for User Story 2

- [x] T027 [US2] Update `stacks/example/versions.tf` — set `required_version = ">= 1.12"`, kubernetes `~> 3.2` (was `2.32.0`), helm `~> 3.2` (was `2.15.0`), http `~> 3.6` (was `3.4.5`), google `>= 7.10, < 8`, google-beta `>= 7.10, < 8` (depends on T047, T048 complete)
  - **Verify**: `grep -E '"[0-9]+\.[0-9]+\.[0-9]+"' stacks/example/versions.tf` returns empty (no exact pins); file shows `~> 3.2` for both kubernetes and helm

- [x] T028 [US2] Run `terraform -chdir=stacks/example init -upgrade -no-color` to regenerate `.terraform.lock.hcl` with updated provider resolutions
  - **Verify**: `terraform init` exits 0; `stacks/example/.terraform.lock.hcl` timestamp updated; `grep "kubernetes" .terraform.lock.hcl` shows `3.2.x` resolved version

- [x] T029 [US2] Stage and verify the updated `stacks/example/.terraform.lock.hcl` — confirm kubernetes 3.x and helm 3.x hashes present, old 2.x hashes absent
  - **Verify**: `grep "2.32.0" stacks/example/.terraform.lock.hcl` returns empty; `grep "2.15.0" stacks/example/.terraform.lock.hcl` returns empty; `grep -c "3\." stacks/example/.terraform.lock.hcl` returns non-zero

- [x] T049 [US2] Run floci services stack and validate kubernetes + helm provider resources via integration test: `./tests/local-gcp-stack/init.sh` then `terraform -chdir=stacks/example test -test-directory=tests/ -filter=integration`; confirm kubernetes namespace and helm_release resources in plan exit 0 (depends on Phase 2 complete + T047/T048)
  - **Verify**: Integration test exits 0; output contains no kubernetes or helm provider errors; `./tests/local-gcp-stack/teardown.sh` runs cleanly

- [x] T030 [US2] Run `terraform -chdir=stacks/example test -test-directory=tests/` to confirm stack unit tests pass with updated constraints
  - **Verify**: Script exits 0, `0 assertions failed`

**Checkpoint**: Stack versions.tf uses 3.x range constraints for kubernetes/helm; breaking HCL changes fixed; lock file regenerated; floci and unit tests pass.

---

## Phase 5: User Story 3 — Unified Upper-Bound Strategy for Google Provider (Priority: P3)

**Goal**: `examples/ha-vpn/versions.tf` updated with `required_version >= 1.12` and
google/google-beta `>= 7.10, < 8`. All modules and stack verified against compliance matrix.

**Independent Test**: Compliance grep commands from `contracts/version-matrix.md` all return empty output.

### Tests for User Story 3 ⚠️ Write FIRST

- [x] T031 [US3] Create `examples/ha-vpn/tests/unit.tftest.hcl` — mock_provider "google", mock_provider "google-beta"; assert plan succeeds (validates module compiles with new constraints)
  - **Verify**: `terraform -chdir=examples/ha-vpn test` exits 0

### Implementation for User Story 3

- [x] T032 [US3] Update `examples/ha-vpn/versions.tf` — set `required_version = ">= 1.12"`, google `>= 7.10, < 8`, google-beta `>= 7.10, < 8`; update provider_meta to `terraform-google-network/v9.4.0`
  - **Verify**: `terraform -chdir=examples/ha-vpn validate` exits 0 AND `terraform -chdir=examples/ha-vpn test` exits 0

- [x] T033 [US3] Run compliance matrix verification — execute all grep commands from `contracts/version-matrix.md` section "Verification Commands"; confirm `>= 7.10` floor and `< 8` upper bound across all files; confirm `>= 1.12` required_version in all files
  - **Verify**: All grep commands exit 0 with no output (no legacy constraints, no exact pins, no missing lower or upper bounds)

**Checkpoint**: All `versions.tf` files comply with the version matrix. US3 independently testable.

---

## Phase 6: User Story 4 — Update GKE Module Version Reference (Priority: P3)

**Goal**: `stacks/example/gke-private.tf` references `~> 44.0` of the kubernetes-engine module.
Deprecated `network_policy` attribute removed. `terraform validate` passes. Floci integration tests pass.

**Independent Test**: `terraform -chdir=stacks/example validate` exits 0 with no deprecated-attribute warnings.
Integration test against floci stack exits 0.

### Tests for User Story 4 ⚠️ Write FIRST

- [x] T034 [US4] Create `stacks/example/tests/integration.tftest.hcl` — uses real providers pointed at emulator stack (STORAGE_EMULATOR_HOST); asserts `terraform plan` exits 0 for the GCS backend initialization
  - **Verify**: With floci stack running (`./tests/local-gcp-stack/init.sh`), `terraform -chdir=stacks/example test -test-directory=tests/ -filter=integration` exits 0

### Implementation for User Story 4

- [x] T035 [US4] Update GKE module version in `stacks/example/gke-private.tf` — change `version = "~> 32.0"` to `version = "~> 44.0"`
  - **Verify**: File shows `version = "~> 44.0"` and `grep "~> 32" stacks/example/gke-private.tf` returns empty

- [x] T036 [US4] Remove deprecated `network_policy = false` attribute from GKE module block in `stacks/example/gke-private.tf` (removed in v33+ of upstream module); audit v32→v44 release notes for any additional removed or renamed variables and apply fixes
  - **Verify**: `grep "network_policy" stacks/example/gke-private.tf` returns empty; all other v44 breaking changes addressed

- [x] T037 [US4] Run `terraform -chdir=stacks/example init -upgrade -no-color` to download the v44 GKE module
  - **Verify**: Init exits 0; `.terraform/modules/` contains `example-gke-private` resolved at `44.x`

- [x] T038 [US4] Run `terraform -chdir=stacks/example validate -no-color` to confirm no deprecated attribute errors from the v44 GKE module
  - **Verify**: Validate exits 0; output contains `Success! The configuration is valid.`; no warnings referencing v32-era deprecated attributes

- [x] T039 [US4] Run floci integration test: `./tests/local-gcp-stack/init.sh && ./tests/run-integration-tests.sh && ./tests/local-gcp-stack/teardown.sh`
  - **Verify**: `run-integration-tests.sh` exits 0; output shows `All integration tests passed.`

**Checkpoint**: GKE module at v44, deprecated attrs removed, validate passes, floci integration tests pass.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Ensure all hooks pass, docs are regenerated, and the upgrade is end-to-end verified.

- [x] T041 Update `.terraform-docs.yml` — change `version: ">= 0.12.0, < 1.0.0"` to `version: ">= 0.18.0, < 1.0.0"` in `.terraform-docs.yml` (must run BEFORE T040 to ensure correct terraform-docs version is expected by pre-commit)
  - **Verify**: `grep "0.18" .terraform-docs.yml` returns a match

- [x] T040 [P] Run `terraform-docs markdown . --output-file README.md` for each module that had `versions.tf` changes — regenerates README with updated `required_providers` table in `modules/networks/firewall-rules/`, `routes/`, `subnets/`, `router-nat/`, `vpc/`, `vpn-classic/`, `vpn-ha/`, `modules/sql/postgresql/`, `modules/workload/artifact-registry/`
  - **Verify**: `git diff --name-only` shows README.md files updated; no `<!-- BEGIN_TF_DOCS -->` sections are stale

- [x] T042 Run `pre-commit run --all-files` to verify all hooks (`terraform-fmt`, `tflint`, `terraform-docs-go`) pass
  - **Verify**: `pre-commit run --all-files` exits 0; no hook failures reported

- [x] T043 Run end-to-end quickstart validation from `specs/001-upgrade-providers-modules/quickstart.md` Steps 1–6
  - **Verify**: All 6 quickstart steps produce expected output (Step 1: no legacy constraints; Step 2: all validate succeed; Step 3: init resolves kubernetes 3.2.x, helm 3.2.x, google 7.x; Step 4: 0 assertions failed; Step 5: integration tests pass; Step 6: pre-commit clean)

- [x] T044 [P] Confirm `stacks/example/.terraform.lock.hcl` is staged for commit with updated provider versions
  - **Verify**: `grep "2.32.0\|2.15.0\|3.4.5" stacks/example/.terraform.lock.hcl` returns empty (old exact-pin hashes gone); lock file contains kubernetes 3.x, helm 3.x, google 7.x hash entries

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (directory structure) — blocks T034, T039, T049 (integration tests)
- **US1 (Phase 3)**: Depends on Phase 1 completion — no dependency on Phase 2
- **US2 (Phase 4)**: T045/T046 (audit) start after Phase 1; T047/T048 depend on T045/T046; T027 depends on T047/T048; T049 depends on Phase 2 + T047/T048
- **US3 (Phase 5)**: Depends on Phase 1 only; can run in parallel with US1 and US2
- **US4 (Phase 6)**: T034/T039 depend on Phase 2 (floci stack); T035–T038 depend on Phase 1 only
- **Polish (Phase 7)**: Depends on all user story phases completing; T041 must precede T040

### User Story Dependencies

- **US1 (P1)**: Starts after Phase 1 — independent
- **US2 (P2)**: Audit tasks (T045/T046) start after Phase 1; HCL fix tasks (T047/T048) depend on audit; floci test (T049) depends on Phase 2 + fixes
- **US3 (P3)**: Starts after Phase 1 — independent (can run in parallel with US1/US2)
- **US4 (P3)**: Integration tests (T034, T039) depend on Foundational phase (floci stack)

### Within Each User Story

- Test files MUST be created and run BEFORE implementation tasks
- `validate` before `test` — validate catches syntax errors, test validates contracts
- `init` before `validate` when provider constraints change
- FR-010 audit tasks (T045/T046) MUST complete before HCL fix tasks (T047/T048)
- Compliance greps run AFTER all versions.tf edits are complete

---

## Parallel Opportunities

### Maximum parallelism within Phase 3 (US1)

```bash
# All test file creations can run in parallel (T007–T015):
terraform -chdir=modules/networks/firewall-rules test   # T007
terraform -chdir=modules/networks/routes test           # T008
terraform -chdir=modules/networks/subnets test          # T009
terraform -chdir=modules/networks/router-nat test       # T010
terraform -chdir=modules/networks/vpc test              # T011
terraform -chdir=modules/networks/vpn-classic test      # T012
terraform -chdir=modules/networks/vpn-ha test           # T013
terraform -chdir=modules/sql/postgresql test            # T014
terraform -chdir=modules/workload/artifact-registry test # T015

# All versions.tf edits can run in parallel (T016–T024) after tests exist
```

### Phase 4 internal parallelism

```bash
# T045 and T046 (changelog audits) can run in parallel
# T047 and T048 (HCL fixes) can run in parallel after their respective audits
# T027 can follow T047+T048 once both are done
```

### Cross-story parallelism (after Phase 1 complete)

```bash
# Developer A → US1 (T007–T025)
# Developer B → US2 audit + fixes (T026, T045, T046, T047, T048)
# Developer C → US3 + US4 implementation (T031–T033, T035–T038)
# Developer D → Foundational floci stack (T004–T006, unblocks T034, T039, T049)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 3: US1 — all 9 module version updates + unit tests (T007–T025)
3. **STOP and VALIDATE**: `./tests/run-unit-tests.sh` → 0 assertions failed for all 9 modules
4. US1 is independently deliverable and verifiable

### Incremental Delivery

1. Phase 1 → Phase 3 (US1): Module version floor raised, unit test suite in place
2. Add Phase 4 (US2): Audit → HCL fixes → stack constraint update → floci validation
3. Add Phase 5 (US3): Examples updated; full compliance matrix verified
4. Add Phase 2 + Phase 6 (US4): floci stack + GKE v44 upgrade + integration tests
5. Phase 7: Polish (T041 before T040), docs, final end-to-end verification

---

## Notes

- Every task has a **Verify** line — complete the verify check before checking the box
- `[P]` tasks = different files, no dependencies within phase — safe to run in parallel
- `[Story]` label maps each task to its user story for traceability (Constitution Principle IX)
- Tests written FIRST per story; run before and after implementation to confirm no regression
- T045/T046 (changelog audits) are research tasks — findings go in PR description or inline notes
- Integration tests (T034, T039, T049) require Docker and the floci services stack running
- `provider_meta.module_name` version strings in T016–T024 should be verified against upstream GitHub releases at implementation time; update if actual upstream versions differ
- Do NOT manually edit `modules/*/README.md` — these are managed by `terraform-docs` (T040)
- T041 MUST execute before T040 (terraform-docs version config before running terraform-docs)
