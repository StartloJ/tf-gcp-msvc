# Feature Specification: AI/ML Platform Shared Modules

**Feature Branch**: `002-ai-ml-modules`

**Created**: 2026-07-08

**Status**: Draft

**Input**: Develop new shared Terraform modules for 22 GCP services (Platform + AI categories) that AI/ML workloads depend on, following the same module structure as existing `modules/networks/`, `modules/workload/`, and `modules/sql/` modules.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Data Processing & Storage Infrastructure (Priority: P1)

A data platform engineer needs to provision the core data tier for AI/ML workloads: distributed data processing clusters (Dataproc), object storage (Cloud Storage / GCS), and analytical storage/query capabilities (BigQuery). These are the foundational compute and storage services that every AI/ML pipeline depends on.

**Why this priority**: Without data processing and storage, no AI/ML workload can run. These are the blocking dependencies for all other stories.

**Independent Test**: A platform engineer can call the Dataproc module, GCS module, and BigQuery module independently in a test stack and confirm that master node, worker pool, storage bucket, and BigQuery dataset are all plannable with zero errors.

**Acceptance Scenarios**:

1. **Given** a stack supplies `org`, `domain`, `env`, and `region_code` variables, **When** the Dataproc module is called with master machine type `n2-standard-4` and workers `n2-standard-8`, **Then** a plan shows a Dataproc cluster with correctly named master and worker groups and `common_labels` applied.
2. **Given** a GCS module call with replication destination set to Singapore region, **When** a plan is run, **Then** the bucket is planned with versioning enabled and cross-region replication configured (DR Storage use case).
3. **Given** a BigQuery module call specifying active and long-term storage with a dataset, **When** a plan is run, **Then** the dataset is planned with table expiration policies reflecting active vs. long-term storage classification.
4. **Given** any module is called without required variables, **When** a plan is run, **Then** Terraform validation fails with a descriptive error message identifying the missing variable.

---

### User Story 2 — Security & Secret Management (Priority: P1)

A security engineer needs to enforce organisation-wide security controls for AI/ML stacks as infrastructure code: secret storage (Secret Manager), encryption key management (Cloud KMS), and sensitive data inspection/de-identification (Cloud DLP). These controls are non-negotiable and must be available as reusable modules.

**Why this priority**: Security controls are a constitution-level requirement (Principle II). No AI/ML stack should be deployable without the ability to wire in secrets management and encryption.

**Independent Test**: A security engineer can call each security module independently and confirm that secrets, key rings, and DLP inspection templates are plannable with the correct IAM bindings and `common_labels`.

**Acceptance Scenarios**:

1. **Given** a Secret Manager module call with a secret name and optional initial value, **When** a plan is run, **Then** the secret is planned with automatic replication and `common_labels` applied; no plaintext value appears in state output.
2. **Given** a KMS module call specifying a key ring and one or more crypto keys with rotation period, **When** a plan is run, **Then** key ring and keys are planned with `prevent_destroy = true` lifecycle and correct IAM bindings for the calling service account.
3. **Given** a DLP module call specifying inspection templates and info types, **When** a plan is run, **Then** the DLP inspection template is planned; the module outputs the template ID for downstream use.
4. **Given** a Dataplex module call for data governance on a lake/zone structure, **When** a plan is run, **Then** a Dataplex lake and at least one zone are planned with governance policies and `common_labels`.

---

### User Story 3 — Connectivity & API Exposure (Priority: P2)

A network/platform engineer needs reusable modules to expose AI/ML services to consumers: an HTTP(S) load balancer for serving model endpoints, Private Service Connect for private API access, and network egress management. The HA VPN module already exists; this story extends connectivity coverage.

**Why this priority**: AI/ML model serving requires traffic management and private connectivity. These are deployment blockers for production workloads but not for data processing or security setup.

**Independent Test**: A network engineer can call the HTTP(S) Load Balancer module and PSC module independently; plans succeed with named backend services, forwarding rules, and PSC endpoints respectively.

**Acceptance Scenarios**:

1. **Given** an HTTP(S) Load Balancer module call with backend service URLs and SSL certificate config, **When** a plan is run, **Then** a global forwarding rule, target proxy, URL map, and backend service are planned; `common_labels` are applied where the resource type supports them.
2. **Given** a Private Service Connect module call specifying a service attachment and consumer subnet, **When** a plan is run, **Then** a PSC endpoint is planned in the consumer VPC without requiring a public IP.
3. **Given** a Secure Web Proxy module call with `allowed_url_patterns` containing permitted destinations and `default_action = "deny"`, **When** a plan is run, **Then** an SWP gateway, security policy, and proxy-only subnet are planned that enforce HTTP/HTTPS egress control; the module outputs the proxy IP for workload routing.

---

### User Story 4 — Application Runtime & API Management (Priority: P2)

A workload engineer needs modules for serverless compute (Cloud Run) and API management (API Gateway, Cloud Endpoints) to deploy AI/ML inference services and expose them through managed API contracts.

**Why this priority**: Model serving and API exposure are the consumer-facing layer. Depends on connectivity (US3) but can be module-developed in parallel.

**Independent Test**: A workload engineer can call the Cloud Run module and API Gateway module independently and confirm a Cloud Run service and API config are plannable with correct IAM for invoker access.

**Acceptance Scenarios**:

1. **Given** a Cloud Run module call with container image reference, memory, and CPU limits, **When** a plan is run, **Then** a Cloud Run service is planned with `noauth` or IAM invoker binding as specified, and `common_labels` applied.
2. **Given** an API Gateway module call with an OpenAPI spec reference and backend URL, **When** a plan is run, **Then** an API Gateway API config and gateway are planned; the module outputs the default hostname.
3. **Given** a Cloud Endpoints module call specifying a service name and config file, **When** a plan is run, **Then** a Cloud Endpoints service is planned with the specified configuration deployed.

---

### User Story 5 — Observability & Disaster Recovery (Priority: P3)

A platform reliability engineer needs a Cloud Logging module to centralise log routing for AI/ML workloads, and DR capabilities (cross-region GCS replication to Singapore, Dataproc standby cluster) to meet recovery objectives.

**Why this priority**: Observability and DR are operational concerns that come after core services are functional. DR Storage reuses the GCS module (US1) with DR-specific configuration.

**Independent Test**: A reliability engineer can call the Cloud Logging module and confirm log sinks and bucket configuration are plannable; can call the Dataproc module with a standby flag and confirm a secondary cluster is planned.

**Acceptance Scenarios**:

1. **Given** a Cloud Logging module call with log sink destination and filter, **When** a plan is run, **Then** a log sink, logging bucket, and exclusion rules are planned; the module outputs the sink writer identity for IAM wiring.
2. **Given** a GCS module call with `dr_replication_region = "asia-southeast1"` (Singapore), **When** a plan is run, **Then** the bucket replication rule targets the Singapore region and the module outputs the replica bucket name.
3. **Given** a Dataproc module call with `enable_dr_standby = true` and a `dr_region` specified, **When** a plan is run, **Then** a secondary Dataproc cluster is planned in the DR region with the same job configuration as the primary, ready to receive failover traffic.

---

### Edge Cases

- What happens when a KMS key is requested for deletion? (Module MUST enforce `prevent_destroy`; operator must remove lifecycle block manually and re-plan.)
- How does the DLP module handle regions where DLP is not available? (Module must validate `region` against supported DLP regions and fail with a clear error.)
- What happens when Cloud Run is called with `allow_unauthenticated = true` in a `prd` environment? (Module should emit a validation warning or error to prevent unauthenticated public endpoints in production.)
- How does the BigQuery module handle long-term storage transitions? (Table expiration policy is set at dataset level; individual table overrides are out of scope for v1.)
- What happens when DR Storage replication destination equals the source region? (Module must validate that source and DR region are different and fail with a clear error.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every new module MUST follow the existing directory contract: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and auto-generated `README.md`.
- **FR-002**: Every new module MUST declare a `variable "labels"` input (`map(string)`, default `{}`) and apply `common_labels` to all resources that support the `labels` attribute in provider v7.
- **FR-003**: Every new module MUST declare a `variable "project_id"` (string, no default) and a `variable "region"` (string, default `"asia-southeast1"`).
- **FR-004**: Resource names within each module MUST be constructed from naming-token variables (`org`, `domain`, `env`, `region_code`) per the naming convention in `contracts/naming-policy.md` — no hardcoded name strings.
- **FR-005**: The Dataproc module MUST support configurable master machine type (default `n2-standard-4`) and worker machine type (default `n2-standard-8`) with configurable worker count.
- **FR-006**: The Cloud Storage module MUST support optional cross-region replication (DR use case) via a `dr_replication_region` variable; when set, replication is configured to the specified region.
- **FR-007**: The BigQuery module MUST support separate active-storage and long-term-storage datasets or table expiration policies; it MUST output dataset IDs for downstream reference.
- **FR-008**: The Secret Manager module MUST NOT output secret plaintext values; it MUST output only the secret resource name and version resource name.
- **FR-009**: The Cloud KMS module MUST enforce `prevent_destroy = true` on key rings and crypto keys by default; this MUST be overridable only by explicitly setting `prevent_destroy = false`.
- **FR-010**: The HTTP(S) Load Balancer module MUST support both external (global) and internal configurations, selectable via a `load_balancer_type` variable (`"external"` or `"internal"`).
- **FR-011**: The Cloud Run module MUST support both authenticated (IAM-controlled) and unauthenticated access modes; `allow_unauthenticated = true` MUST be blocked by validation when `var.env == "prd"`.
- **FR-012**: Every new module MUST include a `tests/unit.tftest.hcl` file with at least one `plan`-mode run using `mock_provider "google" {}` that passes assertions on naming and labels.
- **FR-013**: The Cloud Logging module MUST support configurable log sink destinations (Cloud Storage bucket, BigQuery dataset, or Pub/Sub topic) selectable via a `sink_destination_type` variable.
- **FR-014**: The Private Service Connect module MUST accept a `service_attachment_uri` variable and output the PSC endpoint IP address for use in DNS configuration.
- **FR-015**: All new modules MUST be added to `./tests/run-unit-tests.sh` so they are included in the repository-wide test run.

### Key Entities

- **Module**: A standalone Terraform configuration unit under `modules/<category>/<name>/` with a single, clearly named responsibility.
- **Stack**: A composition of modules under `stacks/<name>/` that wires modules together for a specific environment. New modules will be demonstrated in `stacks/example/` additions.
- **common_labels**: A 10-key map defined once per stack in `locals.tf`, passed as `labels = local.common_labels` to every module call.
- **Naming Local**: A stack-level `locals {}` entry (e.g., `dataproc_name`, `gcs_name`) constructed from naming tokens per `contracts/naming-policy.md`.
- **DR Replica**: A secondary resource provisioned in a different region (`asia-southeast1` / Singapore) for disaster recovery, reusing the primary module with DR-specific variable values.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 13 new modules pass `terraform validate` and their unit tests with zero assertion failures when the repository-wide `./tests/run-unit-tests.sh` is run.
- **SC-002**: `pre-commit run --all-files` passes for all new module files on first attempt (terraform-fmt, tflint, terraform-docs-go all green).
- **SC-003**: A platform engineer can provision a complete AI/ML data-processing stack (Dataproc + GCS + BigQuery + Secret Manager + KMS) by writing a stack that calls the new modules, with no copy-paste of resource blocks — only module calls.
- **SC-004**: Every new module's `variables.tf` has zero `any`-typed variables (per constitution Principle II); all inputs carry descriptions and types.
- **SC-005**: Naming convention compliance check (grep for hardcoded names) returns zero matches across all new module `main.tf` files — all names are assembled from variables.
- **SC-006**: The DR configuration (GCS replication to Singapore + Dataproc standby) can be enabled/disabled by a single variable flip per module without modifying resource blocks.
- **SC-007**: Security module unit tests verify that secret plaintext does not appear in any output value and that KMS keys have `prevent_destroy` enforced.

## Assumptions

- New modules follow the same provider version constraints as existing modules (`hashicorp/google >= 7.10, < 8` and `hashicorp/google-beta >= 7.10, < 8`).
- The Artifact Registry module for model storage (`AI` category) already exists at `modules/workload/artifact-registry` and does not require a new module — only a usage example in the AI/ML stack demonstrating model-storage repository format.
- Enterprise HTTP/HTTPS egress management uses GCP Secure Web Proxy (`modules/networks/secure-web-proxy`) for URL-based policy enforcement. Cloud NAT (`modules/networks/router-nat`) remains for non-HTTP egress (TCP/UDP). These two modules are complementary: SWP handles inspectable HTTP/S traffic; Cloud NAT handles all other outbound traffic.
- HA VPN already exists at `modules/networks/vpn-ha`; no new VPN module is created. If the AI/ML stack needs HA VPN, it calls the existing module.
- Cloud DLP, Dataplex, and API Gateway are provisioned in `asia-southeast1` (Singapore) by default; DLP availability in other regions must be verified by the caller.
- DR Storage region is hardcoded to `asia-southeast1` (Singapore) in the stack `locals.tf` when DR is enabled; the module accepts any valid region string.
- Dataproc standby (DR Compute) is a separate Dataproc cluster in the DR region — not a Dataproc HA configuration (which is a different feature).
- Cloud Endpoints is distinct from API Gateway; both modules are created independently even though they serve similar purposes, because they have different resource schemas.
- Module composition (wiring new modules together in a stack) is out of scope for this feature's spec — only the modules themselves are in scope. Stack integration examples are included as acceptance-test vehicles only.
- All new modules will be grouped under new top-level categories: `modules/security/`, `modules/data/`, `modules/storage/`, `modules/api/`, `modules/observability/`, and `modules/governance/` — extending the taxonomy defined in constitution Principle I.
