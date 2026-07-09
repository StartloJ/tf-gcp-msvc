# Data Model: AI/ML Platform Shared Modules

**Feature**: `002-ai-ml-modules` | **Date**: 2026-07-08

## Core Entities

### Module
The primary unit. Every module is a standalone Terraform configuration under `modules/<category>/<name>/`.

**Attributes:**
- `category`: `networks | workload | security | governance | data | storage | api | observability`
- `name`: kebab-case identifier (e.g., `secret-manager`, `secure-web-proxy`)
- `files`: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `tests/unit.tftest.hcl`
- `labels_supported`: whether the primary GCP resource accepts a `labels` attribute in provider v7

**Standard input variables (all modules)**:
| Variable | Type | Default | Required |
|---|---|---|---|
| `project_id` | `string` | — | yes |
| `region` | `string` | `"asia-southeast1"` | no |
| `labels` | `map(string)` | `{}` | no |
| `org` | `string` | — | yes |
| `domain` | `string` | — | yes |
| `env` | `string` | — | yes |
| `region_code` | `string` | — | yes |

**Standard output (all modules)**:
| Output | Type | Description |
|---|---|---|
| `<resource>_name` | `string` | GCP resource name (constructed from naming tokens) |
| `<resource>_id` | `string` | GCP resource self_link or id |

---

## Module Catalogue

### networks/psc

**Responsibility**: Create a PSC consumer endpoint in a VPC — either for Google API bundles or for a specific service attachment.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `network_id` | `string` | — | VPC self_link |
| `subnet_id` | `string` | — | Subnet for regional endpoint (Pattern B) |
| `psc_type` | `string` | `"google-apis"` | `"google-apis"` or `"service-attachment"` |
| `service_attachment_uri` | `string` | `""` | Required when `psc_type = "service-attachment"` |
| `create_dns_zone` | `bool` | `true` | For google-apis: create private DNS zone for *.googleapis.com |

| Output | Type |
|---|---|
| `psc_endpoint_ip` | `string` |
| `psc_forwarding_rule_name` | `string` |

**GCP resources**: `google_compute_global_address` / `google_compute_address`, `google_compute_global_forwarding_rule` / `google_compute_forwarding_rule`, `google_dns_managed_zone`, `google_dns_record_set`

---

### networks/load-balancer

**Responsibility**: HTTP(S) Application Load Balancer — external global or internal regional.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `load_balancer_type` | `string` | `"external-global"` | `"external-global"` or `"internal-regional"` |
| `backend_service_backends` | `list(object)` | — | NEG or instance group refs |
| `ssl_certificate_domains` | `list(string)` | `[]` | For managed cert (external only) |
| `custom_ssl_certificate_id` | `string` | `""` | Self-managed cert (overrides domains) |
| `url_map_rules` | `list(object)` | `[]` | Path-based routing rules |
| `health_check_path` | `string` | `"/healthz"` | Backend health check path |

| Output | Type |
|---|---|
| `load_balancer_ip` | `string` |
| `backend_service_id` | `string` |
| `url_map_id` | `string` |

**GCP resources**: `google_compute_backend_service`, `google_compute_url_map`, `google_compute_target_https_proxy`, `google_compute_global_forwarding_rule` / `google_compute_forwarding_rule`, `google_compute_managed_ssl_certificate`

---

### networks/secure-web-proxy

**Responsibility**: Enterprise HTTP/HTTPS egress control via GCP Secure Web Proxy.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `subnet_cidr` | `string` | — | CIDR for proxy-only subnet |
| `allowed_url_patterns` | `list(string)` | `[]` | FQDN or URL regex patterns to allow |
| `denied_url_patterns` | `list(string)` | `[]` | FQDN or URL regex patterns to deny |
| `default_action` | `string` | `"deny"` | Default rule action (`"allow"` or `"deny"`) |
| `enable_tls_inspection` | `bool` | `false` | Whether to enable TLS intercept |
| `certificate_map_id` | `string` | `""` | Required when `enable_tls_inspection = true` |

| Output | Type |
|---|---|
| `proxy_ip` | `string` |
| `proxy_name` | `string` |
| `security_policy_id` | `string` |

**GCP resources**: `google_compute_subnetwork` (proxy-only), `google_network_security_gateway_security_policy`, `google_network_security_gateway_security_policy_rule`, `google_network_services_gateway`

---

### workload/cloud-run

**Responsibility**: Cloud Run service with configurable IAM access and optional PSC producer mode.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `service_name_suffix` | `string` | — | Appended to naming local; full name = `cr-<org>-<domain>-<suffix>-<env>` |
| `container_image` | `string` | — | Full image URI |
| `cpu` | `string` | `"1000m"` | CPU limit |
| `memory` | `string` | `"512Mi"` | Memory limit |
| `min_instances` | `number` | `0` | Min instance count |
| `max_instances` | `number` | `10` | Max instance count |
| `allow_unauthenticated` | `bool` | `false` | Validated false when `env == "prd"` |
| `invoker_members` | `list(string)` | `[]` | IAM members granted `roles/run.invoker` |
| `enable_psc_producer` | `bool` | `false` | Expose service via PSC producer attachment |

| Output | Type |
|---|---|
| `service_url` | `string` |
| `service_name` | `string` |
| `service_attachment_uri` | `string` | Non-empty only when `enable_psc_producer = true` |

**GCP resources**: `google_cloud_run_v2_service`, `google_cloud_run_v2_service_iam_member`

---

### security/secret-manager

**Responsibility**: Create Secret Manager secrets with optional automatic replication and IAM bindings. Does NOT output plaintext values.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `secret_id` | `string` | — | Secret resource ID (not the value) |
| `replication_policy` | `string` | `"automatic"` | `"automatic"` or `"user-managed"` |
| `replication_regions` | `list(string)` | `[]` | Required when `replication_policy = "user-managed"` |
| `accessor_members` | `list(string)` | `[]` | IAM members granted `roles/secretmanager.secretAccessor` |
| `initial_value` | `string` | `""` | Optional initial secret value (sensitive, write-only, NOT output) |

| Output | Type |
|---|---|
| `secret_name` | `string` |
| `secret_version_name` | `string` |

**GCP resources**: `google_secret_manager_secret`, `google_secret_manager_secret_version` (sensitive), `google_secret_manager_secret_iam_member`

---

### security/kms

**Responsibility**: Create Cloud KMS key ring and crypto keys with mandatory `prevent_destroy`.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `key_ring_suffix` | `string` | — | Full name = `kr-<org>-<domain>-<suffix>-<env>-<region_code>` |
| `keys` | `map(object)` | — | Key name → `{ rotation_period, algorithm, purpose }` |
| `key_iam_bindings` | `map(list(string))` | `{}` | Key name → IAM members |
| `prevent_destroy` | `bool` | `true` | Lifecycle `prevent_destroy` on key ring and keys |

| Output | Type |
|---|---|
| `key_ring_id` | `string` |
| `key_ids` | `map(string)` | key name → key self_link |

**GCP resources**: `google_kms_key_ring`, `google_kms_crypto_key`, `google_kms_crypto_key_iam_member`

---

### security/dlp

**Responsibility**: Cloud DLP inspection and de-identification templates.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `inspection_template_display_name` | `string` | — | Human-readable name |
| `info_types` | `list(string)` | — | DLP info type names (e.g., `"EMAIL_ADDRESS"`, `"CREDIT_CARD_NUMBER"`) |
| `deidentify_template_display_name` | `string` | `""` | Optional; empty = no de-id template |
| `deidentify_transformation` | `string` | `"REPLACE_WITH_INFO_TYPE"` | Transformation type |

| Output | Type |
|---|---|
| `inspection_template_id` | `string` |
| `deidentify_template_id` | `string` | Empty string if not created |

**GCP resources**: `google_data_loss_prevention_inspect_template`, `google_data_loss_prevention_deidentify_template`

---

### governance/dataplex

**Responsibility**: Dataplex lake, zones, and assets for data governance.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `lake_name_suffix` | `string` | — | Full name = `lake-<org>-<domain>-<suffix>-<env>` |
| `zones` | `map(object)` | — | Zone name → `{ type: "RAW"\|"CURATED", asset_buckets: list(string) }` |
| `data_stewards` | `list(string)` | `[]` | IAM members granted `roles/dataplex.datasteward` |

| Output | Type |
|---|---|
| `lake_id` | `string` |
| `zone_ids` | `map(string)` |

**GCP resources**: `google_dataplex_lake`, `google_dataplex_zone`, `google_dataplex_asset`

---

### data/dataproc

**Responsibility**: Dataproc cluster — master, primary workers, optional secondary workers, and optional DR standby cluster.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `cluster_name_suffix` | `string` | — | Full name = `dpc-<org>-<domain>-<suffix>-<env>-<region_code>-01` |
| `master_machine_type` | `string` | `"n2-standard-4"` | |
| `master_disk_gb` | `number` | `100` | |
| `worker_machine_type` | `string` | `"n2-standard-8"` | |
| `worker_count` | `number` | `2` | Primary worker count |
| `worker_disk_gb` | `number` | `200` | |
| `enable_dr_standby` | `bool` | `false` | When true, provisions secondary cluster in `dr_region` |
| `dr_region` | `string` | `"asia-southeast1"` | Singapore region for DR |
| `subnet_name` | `string` | — | VPC subnet for the cluster |
| `service_account` | `string` | `""` | Dataproc service account email |
| `initialization_actions` | `list(string)` | `[]` | Init action GCS URIs |

| Output | Type |
|---|---|
| `cluster_name` | `string` |
| `cluster_id` | `string` |
| `dr_cluster_name` | `string` | Empty string when `enable_dr_standby = false` |

**GCP resources**: `google_dataproc_cluster` (primary + optional DR)

---

### data/bigquery

**Responsibility**: BigQuery datasets with IAM bindings and table expiration policy for active vs. long-term storage.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `dataset_id_suffix` | `string` | — | Full ID = `ds_<domain>_<suffix>_<env>_<region_code>` (underscores per naming policy) |
| `active_table_expiration_ms` | `number` | `0` | `0` = no expiration (long-term) |
| `delete_contents_on_destroy` | `bool` | `false` | Safety guard |
| `access_bindings` | `list(object)` | `[]` | `{ role, members }` IAM bindings |

| Output | Type |
|---|---|
| `dataset_id` | `string` |
| `dataset_self_link` | `string` |

**GCP resources**: `google_bigquery_dataset`, `google_bigquery_dataset_iam_member`

---

### storage/gcs

**Responsibility**: Cloud Storage bucket with optional DR cross-region replication (Singapore).

| Variable | Type | Default | Notes |
|---|---|---|---|
| `bucket_name_suffix` | `string` | — | Full name = `bkt-<org>-<domain>-<suffix>-<env>-<region_code>-<uniq>` |
| `unique_suffix` | `string` | — | Short suffix to ensure global uniqueness |
| `storage_class` | `string` | `"STANDARD"` | GCS storage class |
| `versioning_enabled` | `bool` | `true` | |
| `dr_replication_region` | `string` | `""` | When set, configures cross-region replication to this region |
| `uniform_bucket_level_access` | `bool` | `true` | Enforces UBLA |
| `lifecycle_rules` | `list(object)` | `[]` | Age-based transition/delete rules |

| Output | Type |
|---|---|
| `bucket_name` | `string` |
| `bucket_url` | `string` |
| `dr_bucket_name` | `string` | Empty string when DR not enabled |

**GCP resources**: `google_storage_bucket`, `google_storage_bucket_replication` (when DR enabled)

---

### api/api-gateway

**Responsibility**: API Gateway API definition, config, and gateway instance.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `api_id_suffix` | `string` | — | Full ID = `ar-<org>-<domain>-<suffix>-<env>` |
| `openapi_spec` | `string` | — | OpenAPI 2.0 YAML content or GCS URI |
| `backend_service_url` | `string` | — | Backend service URL (Cloud Run URL, etc.) |
| `gateway_region` | `string` | `var.region` | Region for gateway deployment |

| Output | Type |
|---|---|
| `api_id` | `string` |
| `gateway_id` | `string` |
| `default_hostname` | `string` |

**GCP resources**: `google_api_gateway_api`, `google_api_gateway_api_config`, `google_api_gateway_gateway`

---

### api/cloud-endpoints

**Responsibility**: Cloud Endpoints service with managed rollout.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `service_name` | `string` | — | Fully-qualified service name (e.g., `api.endpoints.PROJECT.cloud.goog`) |
| `grpc_config` | `string` | `""` | gRPC config YAML (optional) |
| `openapi_config` | `string` | `""` | OpenAPI YAML (optional, for REST) |
| `protoc_output_base64` | `string` | `""` | Base64 proto descriptor (gRPC only) |

| Output | Type |
|---|---|
| `service_name` | `string` |
| `config_id` | `string` |

**GCP resources**: `google_endpoints_service`

---

### observability/cloud-logging

**Responsibility**: Log sink with configurable destination (GCS, BigQuery, Pub/Sub) and optional logging bucket.

| Variable | Type | Default | Notes |
|---|---|---|---|
| `sink_name_suffix` | `string` | — | Full name = `logsink-<org>-<domain>-<suffix>-<env>` |
| `log_filter` | `string` | `""` | Log filter expression (empty = all logs) |
| `sink_destination_type` | `string` | `"logging-bucket"` | `"logging-bucket"`, `"gcs"`, `"bigquery"`, `"pubsub"` |
| `sink_destination_id` | `string` | `""` | Required when type is `gcs`, `bigquery`, or `pubsub` |
| `log_bucket_retention_days` | `number` | `30` | Retention for `logging-bucket` type |
| `exclusions` | `list(object)` | `[]` | `{ name, filter, description }` exclusion rules |

| Output | Type |
|---|---|
| `sink_name` | `string` |
| `sink_writer_identity` | `string` |
| `log_bucket_id` | `string` | Empty when type is not `logging-bucket` |

**GCP resources**: `google_logging_project_sink`, `google_logging_project_bucket_config`

---

## Relationships

```
Stack
 └── calls → Module (one or more)
               ├── outputs service_attachment_uri → networks/psc (Pattern B)
               └── outputs dataset_id / bucket_url → other modules or stack outputs

networks/psc (google-apis type)
 └── provides private access to:
     secret-manager, kms, dlp, dataplex, bigquery, gcs, cloud-logging,
     artifact-registry (all via *.googleapis.com endpoint)

networks/psc (service-attachment type)
 └── consumes service_attachment_uri from:
     workload/cloud-run (when enable_psc_producer = true)
     sql/postgresql (existing — outputs service_attachment_uri)

networks/secure-web-proxy
 └── requires proxy-only subnet (created internally)
 └── complemented by router-nat (existing) for non-HTTP egress

security/kms
 └── key_ids output consumed by:
     storage/gcs (CMEK bucket encryption)
     data/bigquery (CMEK dataset encryption)
     data/dataproc (CMEK cluster encryption)

governance/dataplex
 └── zone assets reference:
     storage/gcs bucket names
     data/bigquery dataset IDs

observability/cloud-logging
 └── sink_destination_id references:
     storage/gcs bucket_url (when sink_destination_type = "gcs")
     data/bigquery dataset_id (when sink_destination_type = "bigquery")
```
