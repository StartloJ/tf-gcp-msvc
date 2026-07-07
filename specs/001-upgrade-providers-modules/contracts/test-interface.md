# Contract: Test Interface

**Feature**: 001-upgrade-providers-modules
**Date**: 2026-07-07

Defines what the test suite exposes and requires, so that CI pipelines and developers
can run tests without knowing the internal implementation.

---

## Unit Tests (Mock Provider — no GCP credentials required)

### Entry point

```bash
# Run all unit tests for a single module
terraform test -test-directory=tests/ <module-dir>

# Run all unit tests project-wide
./tests/run-unit-tests.sh
```

### Location

Each module has a `tests/unit.tftest.hcl` file:

```
modules/<category>/<name>/tests/unit.tftest.hcl
```

### What each unit test validates

| Module | Test assertions |
|---|---|
| `networks/vpc` | `network_name` output equals input variable; routing_mode propagated |
| `networks/subnets` | Subnet count matches input list length; secondary ranges present when specified |
| `networks/firewall-rules` | Ingress and egress rule counts match input list lengths |
| `networks/routes` | Route list rendered without error |
| `networks/router-nat` | Router and NAT resources created; name contains input prefix |
| `networks/vpn-classic` | Gateway resource present; tunnel count matches input |
| `networks/vpn-ha` | HA tunnel pair created; router references match |
| `sql/postgresql` | Instance name not empty; database version propagated to output |
| `workload/artifact-registry` | Repository ID propagated to output; format preserved |

### Mock provider contract

Each `unit.tftest.hcl` uses:

```hcl
mock_provider "google" {
  alias = "test"
}
```

Mocked resources return default (empty/zero) values unless overridden in the test.
Tests MUST use `command = plan` (not `apply`) for mock tests, so no state is created.

---

## Integration Tests (docker-compose GCP stack)

### Prerequisites

1. Docker and docker-compose installed.
2. Terraform 1.9+ installed.
3. Run `./tests/local-gcp-stack/init.sh` — starts the emulator stack.

### Entry point

```bash
# Start local GCP stack
./tests/local-gcp-stack/init.sh

# Run integration tests (requires stack running)
./tests/run-integration-tests.sh

# Tear down local GCP stack
./tests/local-gcp-stack/teardown.sh
```

### Emulator endpoints

| Service | URL | Terraform env var |
|---|---|---|
| fake-gcs (GCS backend) | `http://localhost:4443` | `STORAGE_EMULATOR_HOST=http://localhost:4443` |
| PostgreSQL | `localhost:5432` | Used directly by Cloud SQL proxy test |
| Local Docker registry | `localhost:5000` | Used in Artifact Registry test assertions |

### Integration test scope

Integration tests cover only the services that have local emulators:

| Test | What it proves |
|---|---|
| GCS backend state init | `terraform init` with GCS backend pointing to fake-gcs succeeds |
| Cloud SQL plan | `terraform plan` for `sql/postgresql` produces valid plan against emulated DB |

Tests for GKE, VPC, VPN (no emulator available) remain as mock-provider unit tests only.

---

## Pre-commit / Static Analysis (always-on)

These run on every commit and are non-negotiable gates (see Constitution § IV):

| Check | Command | Pass criterion |
|---|---|---|
| Format | `terraform fmt -check -recursive` | Exit 0, no output |
| Lint | `tflint --recursive` | Exit 0, no errors |
| Docs | `terraform-docs markdown . --output-file README.md` per module | No diff in README |
| Validate | `terraform validate` in each module dir | Exit 0 |
