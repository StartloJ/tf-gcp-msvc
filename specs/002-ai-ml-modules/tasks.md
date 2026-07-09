---
description: "Task list for AI/ML platform shared Terraform modules"
---

# Tasks: AI/ML Platform Shared Modules

**Input**: Design documents from `specs/002-ai-ml-modules/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**Tests**: Unit tests (`.tftest.hcl`) are written as part of each module's implementation — one `tests/unit.tftest.hcl` per module with `mock_provider "google" {}` plan-mode assertions on naming and labels.

**Organization**: 13 new modules grouped by user story. US1 and US2 are both P1 and can proceed in parallel once the foundational phase is complete. US3 and US4 (P2) can begin in parallel after US1/US2. US5 (P3) follows US3/US4.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different module directories — no shared file dependencies)
- **[Story]**: US1–US5 maps to user stories in spec.md
- Every task references exact file paths; contract details in `contracts/module-interfaces.md`

## Module Interface Reference

All modules share the standard base interface (see `contracts/module-interfaces.md`):
- `variables.tf`: `project_id`, `region` (default `"asia-southeast1"`), `org`, `domain`, `env`, `region_code`, `labels` (map(string), default `{}`), plus module-specific vars
- `versions.tf`: `terraform >= 1.12`, `google >= 7.10, < 8`, `google-beta >= 7.10, < 8`
- `outputs.tf`: resource name + resource id at minimum
- `tests/unit.tftest.hcl`: `mock_provider "google" {}`, plan-mode run, naming assert + labels assert

---

## Phase 1: Setup

**Purpose**: Create new module category directories and update the test runner.

- [X] T001 Create new module category directories: `modules/security/`, `modules/governance/`, `modules/data/`, `modules/storage/`, `modules/api/`, `modules/observability/` (and subdirs for each module listed in plan.md)
- [X] T002 Update `tests/run-unit-tests.sh` to include test paths for all 13 new modules: `modules/security/secret-manager`, `modules/security/kms`, `modules/security/dlp`, `modules/governance/dataplex`, `modules/data/dataproc`, `modules/data/bigquery`, `modules/storage/gcs`, `modules/api/api-gateway`, `modules/api/cloud-endpoints`, `modules/observability/cloud-logging`, `modules/networks/psc`, `modules/networks/load-balancer`, `modules/networks/secure-web-proxy`, `modules/workload/cloud-run`

---

## Phase 2: Foundational

**Purpose**: Baseline verification — confirm existing 9 modules still pass before adding new ones.

**⚠️ CRITICAL**: Run before any module implementation to establish a clean baseline.

- [X] T003 Run `./tests/run-unit-tests.sh` and confirm all 9 existing modules pass (0 failures) — this is the regression baseline for the feature branch
- [X] T004 Run `pre-commit run --all-files` on the baseline state and confirm all hooks pass before any new files are added

**Checkpoint**: Baseline confirmed. All 13 new module implementations can now proceed in parallel.

---

## Phase 3: User Story 1 — Data Processing & Storage (Priority: P1) 🎯 MVP

**Goal**: Deliver reusable Terraform modules for Dataproc clusters (master + workers + optional DR standby), Cloud Storage buckets (with optional cross-region replication), and BigQuery datasets (with active/long-term storage control). These are the core compute and storage building blocks for every AI/ML pipeline.

**Independent Test**: `terraform -chdir=modules/data/dataproc test`, `terraform -chdir=modules/storage/gcs test`, and `terraform -chdir=modules/data/bigquery test` all pass with 0 failures independently.

### modules/data/dataproc

- [X] T005 [P] [US1] Create `modules/data/dataproc/versions.tf` (terraform >= 1.12, google >= 7.10 < 8) and `modules/data/dataproc/variables.tf` — declare all variables per `contracts/module-interfaces.md`: base interface (project_id, region, org, domain, env, region_code, labels) plus `cluster_name_suffix`, `master_machine_type` (default `"n2-standard-4"`), `master_disk_gb` (default 100), `worker_machine_type` (default `"n2-standard-8"`), `worker_count` (default 2), `worker_disk_gb` (default 200), `enable_dr_standby` (bool, default false), `dr_region` (default `"asia-southeast1"`), `subnet_name`, `service_account` (default `""`), `initialization_actions` (list, default [])
- [X] T006 [P] [US1] Create `modules/data/dataproc/main.tf` — define `locals { dataproc_name = "dpc-${var.org}-${var.domain}-${var.cluster_name_suffix}-${var.env}-${var.region_code}-01" }`; resource `google_dataproc_cluster` for primary cluster with `master_config.machine_type = var.master_machine_type`, `worker_config.machine_type = var.worker_machine_type`, `worker_config.num_instances = var.worker_count`, labels applied; second `google_dataproc_cluster` resource for DR standby (`count = var.enable_dr_standby ? 1 : 0`) in `var.dr_region` with same config; verify no hardcoded name strings
- [X] T007 [P] [US1] Create `modules/data/dataproc/outputs.tf` — outputs: `cluster_name` (primary cluster name), `cluster_id` (primary cluster id), `dr_cluster_name` (DR cluster name, empty string when `enable_dr_standby = false`)
- [X] T008 [P] [US1] Create `modules/data/dataproc/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_dataproc_cluster` with variables `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", cluster_name_suffix = "etl", subnet_name = "test-subnet", labels = { managed_by = "terraform" } }`; assert `google_dataproc_cluster.primary.cluster_config[0].master_config[0].machine_type == "n2-standard-4"`; assert naming follows pattern; assert `var.labels["managed_by"] == "terraform"`; second run `plan_dataproc_dr_standby` with `enable_dr_standby = true`; assert `length(google_dataproc_cluster.dr) == 1`

### modules/storage/gcs

- [X] T009 [P] [US1] Create `modules/storage/gcs/versions.tf` and `modules/storage/gcs/variables.tf` — base interface plus `bucket_name_suffix` (string), `unique_suffix` (string), `storage_class` (default `"STANDARD"`), `versioning_enabled` (bool, default true), `dr_replication_region` (string, default `""`; validation: `var.dr_replication_region == "" || var.dr_replication_region != var.region`; error: "DR replication region must differ from primary region"), `uniform_bucket_level_access` (bool, default true), `lifecycle_rules` (list(object({ action = string; age_days = number })), default [])
- [X] T010 [P] [US1] Create `modules/storage/gcs/main.tf` — `locals { gcs_bucket_name = "bkt-${var.org}-${var.domain}-${var.bucket_name_suffix}-${var.env}-${var.region_code}-${var.unique_suffix}" }`; `google_storage_bucket` with `uniform_bucket_level_access`, `versioning { enabled = var.versioning_enabled }`, `labels`, dynamic `lifecycle_rule` block; `google_storage_bucket_replication` resource (`count = var.dr_replication_region != "" ? 1 : 0`) targeting `var.dr_replication_region`; verify no hardcoded names
- [X] T011 [P] [US1] Create `modules/storage/gcs/outputs.tf` — outputs: `bucket_name`, `bucket_url`, `dr_bucket_name` (empty string when DR not enabled)
- [X] T012 [P] [US1] Create `modules/storage/gcs/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_standard_bucket` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", bucket_name_suffix = "models", unique_suffix = "a1b2", labels = { managed_by = "terraform" } }`; assert bucket name `== "bkt-test-ml-models-np-sg-a1b2"`; assert `google_storage_bucket.this.uniform_bucket_level_access == true`; assert `google_storage_bucket.this.labels["managed_by"] == "terraform"`; second run `plan_dr_bucket` with `dr_replication_region = "asia-east1"`; assert DR replication resource count `== 1`

### modules/data/bigquery

- [X] T013 [P] [US1] Create `modules/data/bigquery/versions.tf` and `modules/data/bigquery/variables.tf` — base interface plus `dataset_id_suffix` (string; note: dataset ID will use underscores), `active_table_expiration_ms` (number, default 0; 0 means no expiration), `delete_contents_on_destroy` (bool, default false), `access_bindings` (list(object({ role = string; members = list(string) })), default [])
- [X] T014 [P] [US1] Create `modules/data/bigquery/main.tf` — `locals { bq_dataset_id = "ds_${var.domain}_${var.dataset_id_suffix}_${var.env}_${var.region_code}" }`; `google_bigquery_dataset` with `dataset_id = local.bq_dataset_id`, `location = var.region`, `default_table_expiration_ms = var.active_table_expiration_ms == 0 ? null : var.active_table_expiration_ms`, `delete_contents_on_destroy`, `labels`; dynamic `access` block from `var.access_bindings`; `lifecycle { prevent_destroy = false }`; verify no hardcoded names
- [X] T015 [P] [US1] Create `modules/data/bigquery/outputs.tf` — outputs: `dataset_id`, `dataset_self_link`
- [X] T016 [P] [US1] Create `modules/data/bigquery/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_bigquery_dataset` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", dataset_id_suffix = "features", labels = { managed_by = "terraform" } }`; assert dataset ID `== "ds_ml_features_np_sg"`; assert `google_bigquery_dataset.this.labels["managed_by"] == "terraform"`; second run `plan_bigquery_with_expiration` with `active_table_expiration_ms = 2592000000`; assert expiration is set

**Checkpoint**: US1 complete. `./tests/run-unit-tests.sh` MUST show dataproc, gcs, and bigquery as PASS before proceeding.

---

## Phase 4: User Story 2 — Security & Secret Management (Priority: P1)

**Goal**: Deliver reusable Terraform modules for Secret Manager (without exposing plaintext), Cloud KMS key rings + crypto keys (with mandatory prevent_destroy), Cloud DLP inspection/de-identification templates, and Dataplex governance lakes + zones.

**Independent Test**: `terraform -chdir=modules/security/secret-manager test`, `terraform -chdir=modules/security/kms test`, `terraform -chdir=modules/security/dlp test`, and `terraform -chdir=modules/governance/dataplex test` all pass with 0 failures independently.

### modules/security/secret-manager

- [X] T017 [P] [US2] Create `modules/security/secret-manager/versions.tf` and `modules/security/secret-manager/variables.tf` — base interface plus `secret_id` (string), `replication_policy` (string, default `"automatic"`; validation: `contains(["automatic", "user-managed"], var.replication_policy)`), `replication_regions` (list(string), default []), `accessor_members` (list(string), default []), `initial_value` (string, default `""`, `sensitive = true`; MUST NOT appear in any output)
- [X] T018 [P] [US2] Create `modules/security/secret-manager/main.tf` — `google_secret_manager_secret` with `secret_id`, automatic or user-managed replication based on `var.replication_policy`, `labels`; `google_secret_manager_secret_version` (count = `var.initial_value != "" ? 1 : 0`, `secret_data = var.initial_value`, `lifecycle { ignore_changes = [secret_data] }`); `google_secret_manager_secret_iam_member` for each accessor_member; verify no plaintext output anywhere
- [X] T019 [P] [US2] Create `modules/security/secret-manager/outputs.tf` — outputs ONLY: `secret_name` (`google_secret_manager_secret.this.name`), `secret_version_name` (conditional on version existing); MUST NOT output `secret_data`, `initial_value`, or any plaintext value
- [X] T020 [P] [US2] Create `modules/security/secret-manager/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_secret_automatic_replication` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", secret_id = "my-api-key", labels = { managed_by = "terraform" } }`; assert `google_secret_manager_secret.this.replication[0].automatic != null`; assert `var.labels["managed_by"] == "terraform"`; verify outputs contain no sensitive values

### modules/security/kms

- [X] T021 [P] [US2] Create `modules/security/kms/versions.tf` and `modules/security/kms/variables.tf` — base interface plus `key_ring_suffix` (string), `keys` (map(object({ rotation_period = string; algorithm = string; purpose = string })); example `{ cmek = { rotation_period = "2592000s", algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION", purpose = "ENCRYPT_DECRYPT" } }`), `key_iam_bindings` (map(list(string)), default {}; key = key name, value = list of IAM members), `prevent_destroy` (bool, default true)
- [X] T022 [P] [US2] Create `modules/security/kms/main.tf` — `locals { kms_key_ring_name = "kr-${var.org}-${var.domain}-${var.key_ring_suffix}-${var.env}-${var.region_code}" }`; `google_kms_key_ring` with `lifecycle { prevent_destroy = var.prevent_destroy }`; `google_kms_crypto_key` for_each over `var.keys` with `rotation_period`, `destroy_scheduled_duration`, `lifecycle { prevent_destroy = var.prevent_destroy }`; `google_kms_crypto_key_iam_member` for each binding in `var.key_iam_bindings`; verify no hardcoded names
- [X] T023 [P] [US2] Create `modules/security/kms/outputs.tf` — outputs: `key_ring_id`, `key_ids` (map — `{ for k, _ in var.keys : k => google_kms_crypto_key.keys[k].id }`)
- [X] T024 [P] [US2] Create `modules/security/kms/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_kms_key_ring` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", key_ring_suffix = "data", keys = { cmek = { rotation_period = "2592000s", algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION", purpose = "ENCRYPT_DECRYPT" } }, labels = { managed_by = "terraform" } }`; assert key ring name `== "kr-test-ml-data-np-sg"`; assert `google_kms_crypto_key.keys["cmek"].lifecycle[0].prevent_destroy == true`; assert `var.labels["managed_by"] == "terraform"`

### modules/security/dlp

- [X] T025 [P] [US2] Create `modules/security/dlp/versions.tf` and `modules/security/dlp/variables.tf` — base interface plus `inspection_template_display_name` (string), `info_types` (list(string); example `["EMAIL_ADDRESS", "CREDIT_CARD_NUMBER"]`), `deidentify_template_display_name` (string, default `""`), `deidentify_transformation` (string, default `"REPLACE_WITH_INFO_TYPE"`); note: DLP resources don't support `labels` in provider v7 — add `# tflint-ignore: terraform_unused_declarations` above `variable "labels"`
- [X] T026 [P] [US2] Create `modules/security/dlp/main.tf` — `locals { dlp_template_name = "dlpt-${var.org}-${var.domain}-${var.env}-pii-${var.region_code}" }`; `google_data_loss_prevention_inspect_template` with `display_name`, `inspect_config { info_types { name = each } }`; `google_data_loss_prevention_deidentify_template` (count = `var.deidentify_template_display_name != "" ? 1 : 0`) with `deidentify_config { info_type_transformations { transformations { primitive_transformation { replace_with_info_type_config {} } } } }`; verify no hardcoded names
- [X] T027 [P] [US2] Create `modules/security/dlp/outputs.tf` — outputs: `inspection_template_id`, `deidentify_template_id` (empty string when not created)
- [X] T028 [P] [US2] Create `modules/security/dlp/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_dlp_inspection_template` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", inspection_template_display_name = "PII Scanner", info_types = ["EMAIL_ADDRESS"], labels = { managed_by = "terraform" } }`; assert inspection template is planned; assert `var.labels["managed_by"] == "terraform"`; second run `plan_dlp_with_deidentify` with `deidentify_template_display_name = "PII Masker"`; assert deidentify template count `== 1`

### modules/governance/dataplex

- [X] T029 [P] [US2] Create `modules/governance/dataplex/versions.tf` and `modules/governance/dataplex/variables.tf` — base interface plus `lake_name_suffix` (string), `zones` (map(object({ type = string; asset_buckets = list(string) })); type must be `"RAW"` or `"CURATED"`, validation required), `data_stewards` (list(string), default [])
- [X] T030 [P] [US2] Create `modules/governance/dataplex/main.tf` — `locals { dataplex_lake_name = "lake-${var.org}-${var.domain}-${var.lake_name_suffix}-${var.env}" }`; `google_dataplex_lake` with `name`, `location = var.region`, `labels`; `google_dataplex_zone` for_each over `var.zones` with `type`, `resource_spec { location_type = "SINGLE_REGION" }`, `labels`; `google_dataplex_asset` for each bucket in each zone's `asset_buckets` referencing the GCS bucket; `google_dataplex_lake_iam_member` for each data steward; verify no hardcoded names
- [X] T031 [P] [US2] Create `modules/governance/dataplex/outputs.tf` — outputs: `lake_id`, `zone_ids` (map of zone name → zone id)
- [X] T032 [P] [US2] Create `modules/governance/dataplex/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_dataplex_lake` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", lake_name_suffix = "raw", zones = { raw-ingest = { type = "RAW", asset_buckets = ["test-bucket"] } }, labels = { managed_by = "terraform" } }`; assert lake name `== "lake-test-ml-raw-np"`; assert zone type `== "RAW"`; assert `var.labels["managed_by"] == "terraform"`

**Checkpoint**: US2 complete. Run `./tests/run-unit-tests.sh` — secret-manager, kms, dlp, dataplex MUST all show PASS.

---

## Phase 5: User Story 3 — Connectivity & API Exposure (Priority: P2)

**Goal**: Deliver the PSC consumer endpoint module (both google-apis bundle and service-specific patterns), the HTTP(S) Application Load Balancer module, and the Secure Web Proxy module for enterprise egress control.

**Independent Test**: `terraform -chdir=modules/networks/psc test`, `terraform -chdir=modules/networks/load-balancer test`, and `terraform -chdir=modules/networks/secure-web-proxy test` all pass with 0 failures.

### modules/networks/psc

- [X] T033 [P] [US3] Create `modules/networks/psc/versions.tf` and `modules/networks/psc/variables.tf` — base interface plus `network_id` (string), `subnet_id` (string, default `""`; required for `service-attachment` type), `psc_type` (string, default `"google-apis"`; validation: `contains(["google-apis", "service-attachment"], var.psc_type)`; error: "psc_type must be google-apis or service-attachment"), `service_attachment_uri` (string, default `""`; required when `psc_type == "service-attachment"`, enforce via validation), `create_dns_zone` (bool, default true); note: forwarding rule resource supports labels only in some versions — add tflint-ignore if needed
- [X] T034 [P] [US3] Create `modules/networks/psc/main.tf` — `locals { psc_name = "psc-${var.org}-${var.domain}-${var.psc_type == \"google-apis\" ? \"googleapis\" : \"svc\"}-${var.env}-${var.region_code}-01" }`; for `google-apis` type: `google_compute_global_address` (internal), `google_compute_global_forwarding_rule` targeting `"all-apis"` bundle, `google_dns_managed_zone` (private zone for `googleapis.com.`), `google_dns_record_set` (A record pointing to PSC IP); for `service-attachment` type: `google_compute_address` (internal regional), `google_compute_forwarding_rule` with `target = var.service_attachment_uri`; use `count` or `for_each` gated on `var.psc_type`; verify no hardcoded names
- [X] T035 [P] [US3] Create `modules/networks/psc/outputs.tf` — outputs: `psc_endpoint_ip`, `psc_forwarding_rule_name`
- [X] T036 [P] [US3] Create `modules/networks/psc/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_google_apis_type` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", network_id = "test-network", psc_type = "google-apis", labels = { managed_by = "terraform" } }`; assert global address and forwarding rule are planned; assert DNS zone is planned when `create_dns_zone = true`; second run `plan_service_attachment_type` with `psc_type = "service-attachment"`, `service_attachment_uri = "projects/test/regions/asia-southeast1/serviceAttachments/test-sa"`, `subnet_id = "test-subnet"`; assert regional forwarding rule is planned with correct target

### modules/networks/load-balancer

- [X] T037 [P] [US3] Create `modules/networks/load-balancer/versions.tf` and `modules/networks/load-balancer/variables.tf` — base interface plus `load_balancer_type` (string, default `"external-global"`; validation: `contains(["external-global", "internal-regional"], var.load_balancer_type)`), `backend_service_backends` (list(object({ group = string; balancing_mode = string; capacity_scaler = optional(number, 1.0) }))), `ssl_certificate_domains` (list(string), default []), `custom_ssl_certificate_id` (string, default `""`), `url_map_rules` (list(object({ path_prefix = string; backend_service_id = string })), default []), `health_check_path` (string, default `"/healthz"`); note: LB resources support labels selectively — use tflint-ignore on labels variable
- [X] T038 [P] [US3] Create `modules/networks/load-balancer/main.tf` — `locals { lb_name = "lb-${var.org}-${var.domain}-${var.env}" }`; for `external-global`: `google_compute_backend_service`, `google_compute_url_map`, `google_compute_target_https_proxy`, `google_compute_global_forwarding_rule`, `google_compute_managed_ssl_certificate` (when `ssl_certificate_domains` is non-empty); for `internal-regional`: `google_compute_backend_service`, `google_compute_url_map`, `google_compute_region_target_https_proxy`, `google_compute_forwarding_rule`; use count/for_each gated on `var.load_balancer_type`; verify no hardcoded names
- [X] T039 [P] [US3] Create `modules/networks/load-balancer/outputs.tf` — outputs: `load_balancer_ip`, `backend_service_id`, `url_map_id`
- [X] T040 [P] [US3] Create `modules/networks/load-balancer/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_external_global_lb` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", load_balancer_type = "external-global", backend_service_backends = [{ group = "projects/test/zones/asia-southeast1-a/instanceGroups/test-ig", balancing_mode = "UTILIZATION" }], labels = { managed_by = "terraform" } }`; assert `google_compute_global_forwarding_rule.this` is planned; assert `var.labels["managed_by"] == "terraform"`; second run `plan_internal_regional_lb` with `load_balancer_type = "internal-regional"`; assert regional forwarding rule is planned

### modules/networks/secure-web-proxy

- [X] T041 [P] [US3] Create `modules/networks/secure-web-proxy/versions.tf` and `modules/networks/secure-web-proxy/variables.tf` — base interface plus `subnet_cidr` (string; proxy-only subnet CIDR), `allowed_url_patterns` (list(string), default []; FQDN or URL regex patterns to allow), `denied_url_patterns` (list(string), default []; patterns to deny), `default_action` (string, default `"deny"`; validation: `contains(["allow", "deny"], var.default_action)`), `enable_tls_inspection` (bool, default false), `certificate_map_id` (string, default `""`; required when `enable_tls_inspection = true`)
- [X] T042 [P] [US3] Create `modules/networks/secure-web-proxy/main.tf` — `locals { swp_name = "swp-${var.org}-${var.domain}-${var.env}-${var.region_code}" }`; `google_compute_subnetwork` (proxy-only: `purpose = "INTERNAL_HTTPS_LOAD_BALANCER"`, `role = "ACTIVE"`, `ip_cidr_range = var.subnet_cidr`); `google_network_security_gateway_security_policy` with `name`, `description`; `google_network_security_gateway_security_policy_rule` for each URL in `var.allowed_url_patterns` (action = ALLOW) and `var.denied_url_patterns` (action = DENY) plus a default rule; `google_network_services_gateway` with `type = "SECURE_WEB_GATEWAY"`, `scope`, `certificate_urls` (when TLS inspection enabled), `gateway_security_policy`; verify no hardcoded names
- [X] T043 [P] [US3] Create `modules/networks/secure-web-proxy/outputs.tf` — outputs: `proxy_ip`, `proxy_name`, `security_policy_id`
- [X] T044 [P] [US3] Create `modules/networks/secure-web-proxy/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_swp_default_deny` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", network_id = "test-network", subnet_cidr = "10.10.0.0/24", default_action = "deny", labels = { managed_by = "terraform" } }`; assert `google_network_services_gateway.this` is planned; assert security policy is planned; assert proxy-only subnet is planned; assert `var.labels["managed_by"] == "terraform"`; second run `plan_swp_with_allowlist` with `allowed_url_patterns = ["*.googleapis.com", "pypi.org"]`; assert correct number of policy rules are planned

**Checkpoint**: US3 complete. Run `./tests/run-unit-tests.sh` — psc, load-balancer, secure-web-proxy MUST all show PASS.

---

## Phase 6: User Story 4 — Application Runtime & API Management (Priority: P2)

**Goal**: Deliver reusable Terraform modules for Cloud Run services (with prd authentication gate), API Gateway (API + config + gateway), and Cloud Endpoints (service + rollout).

**Independent Test**: `terraform -chdir=modules/workload/cloud-run test`, `terraform -chdir=modules/api/api-gateway test`, and `terraform -chdir=modules/api/cloud-endpoints test` all pass with 0 failures.

### modules/workload/cloud-run

- [X] T045 [P] [US4] Create `modules/workload/cloud-run/versions.tf` and `modules/workload/cloud-run/variables.tf` — base interface plus `service_name_suffix` (string), `container_image` (string), `cpu` (string, default `"1000m"`), `memory` (string, default `"512Mi"`), `min_instances` (number, default 0), `max_instances` (number, default 10), `allow_unauthenticated` (bool, default false; CRITICAL validation: `!(var.allow_unauthenticated && var.env == "prd")`, error: "allow_unauthenticated must be false in prd environment"), `invoker_members` (list(string), default []), `enable_psc_producer` (bool, default false)
- [X] T046 [P] [US4] Create `modules/workload/cloud-run/main.tf` — `locals { cloud_run_name = "cr-${var.org}-${var.domain}-${var.service_name_suffix}-${var.env}" }`; `google_cloud_run_v2_service` with `name`, `location`, `template { containers { image; resources { limits = { cpu = var.cpu; memory = var.memory } } }; scaling { min_instance_count = var.min_instances; max_instance_count = var.max_instances } }`, `labels`; `google_cloud_run_v2_service_iam_member` for `"roles/run.invoker"` when `allow_unauthenticated = true` (member = `"allUsers"`) OR for each member in `var.invoker_members`; when `enable_psc_producer = true`, reference the service's generated PSC attachment (note: Cloud Run PSC is via NEG — `google_compute_region_network_endpoint_group` with `cloud_run { service = ... }`); verify no hardcoded names; verify prd auth validation fires
- [X] T047 [P] [US4] Create `modules/workload/cloud-run/outputs.tf` — outputs: `service_url`, `service_name`, `service_attachment_uri` (cloud run NEG self_link when `enable_psc_producer = true`, else empty string)
- [X] T048 [P] [US4] Create `modules/workload/cloud-run/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_cloud_run_authenticated` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", service_name_suffix = "inference", container_image = "gcr.io/test/inference:latest", invoker_members = ["serviceAccount:test@test-prj.iam.gserviceaccount.com"], labels = { managed_by = "terraform" } }`; assert service name `== "cr-test-ml-inference-np"`; assert `google_cloud_run_v2_service.this.labels["managed_by"] == "terraform"`; assert IAM member is planned; second run `plan_cloud_run_prd_blocks_unauth` with `env = "prd"` and `allow_unauthenticated = true` — this run MUST return an error matching "prd environment" to verify the validation gate works

### modules/api/api-gateway

- [X] T049 [P] [US4] Create `modules/api/api-gateway/versions.tf` and `modules/api/api-gateway/variables.tf` — base interface plus `api_id_suffix` (string), `openapi_spec` (string; OpenAPI 2.0 YAML content), `backend_service_url` (string), `gateway_region` (string, default `""` — falls back to `var.region`); note: API Gateway resources may not support labels — add tflint-ignore
- [X] T050 [P] [US4] Create `modules/api/api-gateway/main.tf` — `locals { api_gateway_name = "apigw-${var.org}-${var.domain}-${var.api_id_suffix}-${var.env}" }`; `google_api_gateway_api` with `api_id`, `labels`; `google_api_gateway_api_config` with `api = google_api_gateway_api.this.api_id`, `openapi_documents { document { path = "spec.yaml"; contents = base64encode(var.openapi_spec) } }`; `google_api_gateway_gateway` with `api_config`, `gateway_id`, `region = coalesce(var.gateway_region, var.region)`; verify no hardcoded names
- [X] T051 [P] [US4] Create `modules/api/api-gateway/outputs.tf` — outputs: `api_id`, `gateway_id`, `default_hostname`
- [X] T052 [P] [US4] Create `modules/api/api-gateway/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_api_gateway` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", api_id_suffix = "model", openapi_spec = "swagger: '2.0'\ninfo:\n  title: test\n  version: v1\npaths: {}", backend_service_url = "https://test.run.app", labels = { managed_by = "terraform" } }`; assert `google_api_gateway_api.this` is planned; assert gateway is planned; assert `var.labels["managed_by"] == "terraform"`

### modules/api/cloud-endpoints

- [X] T053 [P] [US4] Create `modules/api/cloud-endpoints/versions.tf` and `modules/api/cloud-endpoints/variables.tf` — base interface plus `service_name` (string; fully-qualified, e.g. `"api.endpoints.PROJECT.cloud.goog"`), `grpc_config` (string, default `""`), `openapi_config` (string, default `""`), `protoc_output_base64` (string, default `""`, sensitive); validation: `var.grpc_config != "" || var.openapi_config != ""`, error: "Either grpc_config or openapi_config must be provided"; note: Cloud Endpoints doesn't support labels — tflint-ignore
- [X] T054 [P] [US4] Create `modules/api/cloud-endpoints/main.tf` — `google_endpoints_service` with `service_name = var.service_name`, `grpc_config` (when non-empty), `openapi_config` (when non-empty), `protoc_output_base64` (when non-empty); verify no hardcoded names
- [X] T055 [P] [US4] Create `modules/api/cloud-endpoints/outputs.tf` — outputs: `service_name`, `config_id`
- [X] T056 [P] [US4] Create `modules/api/cloud-endpoints/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_cloud_endpoints_rest` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", service_name = "api.endpoints.test-prj.cloud.goog", openapi_config = "swagger: '2.0'\ninfo:\n  title: test\n  version: v1\npaths: {}", labels = { managed_by = "terraform" } }`; assert `google_endpoints_service.this.service_name == "api.endpoints.test-prj.cloud.goog"`; assert `var.labels["managed_by"] == "terraform"`

**Checkpoint**: US4 complete. Run `./tests/run-unit-tests.sh` — cloud-run, api-gateway, cloud-endpoints MUST all show PASS.

---

## Phase 7: User Story 5 — Observability & Disaster Recovery (Priority: P3)

**Goal**: Deliver the Cloud Logging module (log sinks with configurable destinations) and validate that DR capabilities (GCS cross-region replication, Dataproc standby cluster) are functional via the modules built in US1.

**Independent Test**: `terraform -chdir=modules/observability/cloud-logging test` passes with 0 failures; DR test runs in US1 modules also pass.

### modules/observability/cloud-logging

- [X] T057 [P] [US5] Create `modules/observability/cloud-logging/versions.tf` and `modules/observability/cloud-logging/variables.tf` — base interface plus `sink_name_suffix` (string), `log_filter` (string, default `""`), `sink_destination_type` (string, default `"logging-bucket"`; validation: `contains(["logging-bucket", "gcs", "bigquery", "pubsub"], var.sink_destination_type)`), `sink_destination_id` (string, default `""`; required when type is not `logging-bucket`), `log_bucket_retention_days` (number, default 30), `exclusions` (list(object({ name = string; filter = string; description = string })), default []); note: log sink and bucket resources may not support labels — add tflint-ignore
- [X] T058 [P] [US5] Create `modules/observability/cloud-logging/main.tf` — `locals { log_sink_name = "logsink-${var.org}-${var.domain}-${var.sink_name_suffix}-${var.env}" }`; `google_logging_project_bucket_config` (count = `var.sink_destination_type == "logging-bucket" ? 1 : 0`) for managed logging bucket with `retention_days`; `google_logging_project_sink` with `name`, `filter = var.log_filter`, destination set based on `var.sink_destination_type` (logging bucket ARN / GCS URI / BigQuery dataset / Pub/Sub topic), unique writer identity; dynamic `exclusions` block; verify no hardcoded names
- [X] T059 [P] [US5] Create `modules/observability/cloud-logging/outputs.tf` — outputs: `sink_name`, `sink_writer_identity` (IAM member format for granting write access to sink destination), `log_bucket_id` (empty string when type is not `logging-bucket`)
- [X] T060 [P] [US5] Create `modules/observability/cloud-logging/tests/unit.tftest.hcl` — `mock_provider "google" {}` plan run `plan_logging_bucket_sink` with `{ project_id = "test-prj", org = "test", domain = "ml", env = "np", region_code = "sg", sink_name_suffix = "audit", labels = { managed_by = "terraform" } }`; assert sink name `== "logsink-test-ml-audit-np"`; assert logging bucket is planned; assert `var.labels["managed_by"] == "terraform"`; second run `plan_bigquery_sink` with `sink_destination_type = "bigquery"` and `sink_destination_id = "bigquery.googleapis.com/projects/test-prj/datasets/ds_ml_logs_np_sg"`; assert logging bucket count `== 0`; assert sink destination references BigQuery

### DR Validation (using existing US1 modules)

- [X] T061 [US5] Run `terraform -chdir=modules/storage/gcs test -no-color` and confirm the `plan_dr_bucket` run passes — verifies cross-region replication to Singapore is correctly configured when `dr_replication_region` is set
- [X] T062 [US5] Run `terraform -chdir=modules/data/dataproc test -no-color` and confirm the `plan_dataproc_dr_standby` run passes — verifies the standby cluster is planned in the DR region when `enable_dr_standby = true`

**Checkpoint**: US5 complete. Run `./tests/run-unit-tests.sh` — cloud-logging MUST show PASS; DR test runs MUST pass within gcs and dataproc modules.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Repository-wide validation, compliance checks, and test runner coverage verification.

- [X] T063 Run `./tests/run-unit-tests.sh` — all 22 modules (9 existing + 13 new) MUST report PASS with 0 failures; this is the primary acceptance gate
- [X] T064 Run `pre-commit run --all-files` — terraform-fmt, tflint, and terraform-docs-go MUST all pass; fix any formatting or lint issues found; confirm terraform-docs has regenerated README.md for all 13 new modules
- [X] T065 Run naming compliance grep on all new modules: `grep -rn '"dpc-\|"bkt-\|"cr-\|"kr-\|"lake-\|"logsink-\|"psc-\|"swp-\|"lb-\|"apigw-\|"dlpt-\|"ds_' modules/security/ modules/governance/ modules/data/ modules/storage/ modules/api/ modules/observability/ modules/networks/psc modules/networks/load-balancer modules/networks/secure-web-proxy modules/workload/cloud-run --include="main.tf"` — expected: no output (all names assembled from variables)
- [X] T066 [P] Run labels interface check on all 13 new modules (quickstart.md Step 6): `for d in modules/security/* modules/governance/* modules/data/* modules/storage/* modules/api/* modules/observability/* modules/networks/psc modules/networks/load-balancer modules/networks/secure-web-proxy modules/workload/cloud-run; do grep -q 'variable "labels"' "$d/variables.tf" && echo "OK: $d" || echo "MISSING: $d"; done` — expected: all lines print "OK: ..."
- [X] T067 [P] Verify KMS `prevent_destroy` and Secret Manager output safety: run quickstart.md Step 5 security constraint checks — assert `prevent_destroy = true` in KMS lifecycle block; assert no sensitive values in secret-manager outputs.tf
- [X] T068 [P] Verify Cloud Run prd auth gate: run `terraform -chdir=modules/workload/cloud-run test -no-color` and confirm `plan_cloud_run_prd_blocks_unauth` run produces an expected error (validation failure), not a pass
- [X] T069 [P] Verify test runner coverage: run quickstart.md Step 10 — confirm all 13 new module paths are present in `tests/run-unit-tests.sh`
- [X] T070 Run quickstart.md Step 7 (PSC validation) and Step 8 (SWP validation) to confirm both psc_type modes and SWP default-deny are verified by unit tests
- [X] T071 Add module call examples for all 13 new modules in `stacks/example/` — create `stacks/example/ai-ml-modules.tf` demonstrating a complete AI/ML data-processing composition (Dataproc + GCS + BigQuery + Secret Manager + KMS) using only module calls with `labels = local.common_labels`; run `terraform -chdir=stacks/example plan` and confirm 0 errors — this satisfies SC-003

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — verifies baseline before adding new modules
- **US1 (Phase 3) and US2 (Phase 4)**: Both P1 — can proceed in parallel after Foundational
- **US3 (Phase 5) and US4 (Phase 6)**: Both P2 — can proceed in parallel after Foundational; ideally after US1/US2 but are technically independent
- **US5 (Phase 7)**: Depends on US1 (DR validation uses GCS and Dataproc modules from US1)
- **Polish (Phase 8)**: Depends on all user story phases complete

### User Story Dependencies

- **US1 (P1)**: Independent — dataproc, bigquery, gcs modules have no cross-dependencies
- **US2 (P1)**: Independent — secret-manager, kms, dlp, dataplex have no dependencies on US1
- **US3 (P2)**: Independent — psc, load-balancer, secure-web-proxy are standalone modules
- **US4 (P2)**: Independent — cloud-run, api-gateway, cloud-endpoints are standalone modules
- **US5 (P3)**: cloud-logging is independent; DR validation tasks (T061, T062) depend on US1 completion

### Within Each Phase — Parallel Opportunities

All tasks within a user story phase marked `[P]` can run in parallel because they target different module directories. Within a single module, implement in order: variables.tf → main.tf → outputs.tf → tests.

---

## Parallel Execution Example: US1

```bash
# All three modules can be developed in parallel (different directories):
# Developer A: modules/data/dataproc (T005-T008)
# Developer B: modules/storage/gcs (T009-T012)
# Developer C: modules/data/bigquery (T013-T016)
# Each validates independently with: terraform -chdir=modules/<path> test
```

---

## Implementation Strategy

### MVP (US1 + US2 — the two P1 stories)

1. Phase 1: Setup (T001-T002)
2. Phase 2: Foundational baseline (T003-T004)
3. Phase 3: US1 — Dataproc, GCS, BigQuery (T005-T016) in parallel
4. Phase 4: US2 — Secret Manager, KMS, DLP, Dataplex (T017-T032) in parallel
5. **STOP and VALIDATE**: `./tests/run-unit-tests.sh` — 13 modules passing (9 existing + 4 US2 + 3 US1 — wait, this means all US1 and US2 modules). Run pre-commit.

### Full Delivery

1. MVP complete
2. Phase 5: US3 (T033-T044) — PSC + LB + SWP
3. Phase 6: US4 (T045-T056) — Cloud Run + API Gateway + Cloud Endpoints
4. Phase 7: US5 (T057-T062) — Cloud Logging + DR validation
5. Phase 8: Polish (T063-T071) — repository-wide gates + stack composition demo (SC-003)

---

## Notes

- `[P]` tasks within a user story phase target different module directories and can be run by different developers or in parallel in a single session
- All module files follow contracts in `specs/002-ai-ml-modules/contracts/module-interfaces.md`
- All naming patterns follow `specs/002-ai-ml-modules/contracts/naming-conventions.md`
- `tflint-ignore: terraform_unused_declarations` is required on `variable "labels"` for DLP, Cloud Endpoints, API Gateway, and any other module where the provider doesn't support `labels` on the primary resource — this prevents tflint's auto-removal of the interface variable (same pattern as established in `001-upgrade-providers-modules`)
- KMS keys MUST have `lifecycle { prevent_destroy = var.prevent_destroy }` where `prevent_destroy` defaults to `true` — operators who need to destroy keys must explicitly set `prevent_destroy = false` in their stack
- Secret module: `initial_value` MUST be marked `sensitive = true`; the version resource MUST have `lifecycle { ignore_changes = [secret_data] }` to prevent rotation drift; outputs MUST NOT include `secret_data`
- Cloud Run prd gate: the validation on `allow_unauthenticated` MUST produce a descriptive error — test `plan_cloud_run_prd_blocks_unauth` verifies this by expecting an error, not a pass
- GCS bucket names require a caller-supplied `unique_suffix` (4-6 chars) for global uniqueness — the module does not auto-generate this value
- BigQuery dataset IDs use underscores throughout (`ds_<domain>_<suffix>_<env>_<region>`) — not hyphens
