# Module Interface Contracts

**Feature**: `002-ai-ml-modules` | **Date**: 2026-07-08

All 13 new modules share the standard base interface. Module-specific additions follow.

## Standard Base Interface (all modules)

### Inputs (every module declares these)

```hcl
variable "project_id"  { type = string }
variable "region"      { type = string; default = "asia-southeast1" }
variable "org"         { type = string }
variable "domain"      { type = string }
variable "env"         { type = string }
variable "region_code" { type = string }
# tflint-ignore: terraform_unused_declarations (on modules where provider doesn't support labels)
variable "labels"      { type = map(string); default = {} }
```

### Provider version constraint (versions.tf)

```hcl
terraform {
  required_version = ">= 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.10, < 8"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.10, < 8"
    }
  }
}
```

### Unit test contract (tests/unit.tftest.hcl)

Every module MUST include a `mock_provider "google" {}` plan-mode run asserting:
1. Resource name follows naming convention (checked via `== expected_string`)
2. `var.labels["managed_by"] == "terraform"` (or resource attribute if labels supported)
3. At least one business-logic assertion specific to the module

---

## Module-Specific Contracts

### modules/networks/psc

```hcl
# Key inputs beyond base
variable "network_id"            { type = string }
variable "subnet_id"             { type = string; default = "" }
variable "psc_type"              { type = string; default = "google-apis" }
  # validation: contains(["google-apis", "service-attachment"], var.psc_type)
variable "service_attachment_uri" { type = string; default = "" }
variable "create_dns_zone"        { type = bool; default = true }

# Outputs
output "psc_endpoint_ip"           { value = ... }
output "psc_forwarding_rule_name"  { value = ... }
```

### modules/networks/load-balancer

```hcl
variable "load_balancer_type"       { type = string; default = "external-global" }
  # validation: contains(["external-global", "internal-regional"], var.load_balancer_type)
variable "backend_service_backends" { type = list(object({ group = string; balancing_mode = string })) }
variable "ssl_certificate_domains"  { type = list(string); default = [] }
variable "url_map_rules"            { type = list(object({ path_prefix = string; backend_service_id = string })); default = [] }
variable "health_check_path"        { type = string; default = "/healthz" }

output "load_balancer_ip"    { value = ... }
output "backend_service_id"  { value = ... }
output "url_map_id"          { value = ... }
```

### modules/networks/secure-web-proxy

```hcl
variable "subnet_cidr"          { type = string }
variable "allowed_url_patterns" { type = list(string); default = [] }
variable "denied_url_patterns"  { type = list(string); default = [] }
variable "default_action"       { type = string; default = "deny" }
  # validation: contains(["allow", "deny"], var.default_action)
variable "enable_tls_inspection" { type = bool; default = false }
variable "certificate_map_id"    { type = string; default = "" }

output "proxy_ip"            { value = ... }
output "proxy_name"          { value = ... }
output "security_policy_id"  { value = ... }
```

### modules/workload/cloud-run

```hcl
variable "service_name_suffix"    { type = string }
variable "container_image"        { type = string }
variable "cpu"                    { type = string; default = "1000m" }
variable "memory"                 { type = string; default = "512Mi" }
variable "min_instances"          { type = number; default = 0 }
variable "max_instances"          { type = number; default = 10 }
variable "allow_unauthenticated"  { type = bool; default = false }
  # validation: !(var.allow_unauthenticated && var.env == "prd")
  # error: "allow_unauthenticated must be false in prd environment"
variable "invoker_members"        { type = list(string); default = [] }
variable "enable_psc_producer"    { type = bool; default = false }

output "service_url"             { value = ... }
output "service_name"            { value = ... }
output "service_attachment_uri"  { value = var.enable_psc_producer ? ... : "" }
```

### modules/security/secret-manager

```hcl
variable "secret_id"           { type = string }
variable "replication_policy"  { type = string; default = "automatic" }
  # validation: contains(["automatic", "user-managed"], var.replication_policy)
variable "replication_regions" { type = list(string); default = [] }
variable "accessor_members"    { type = list(string); default = [] }
variable "initial_value"       { type = string; default = ""; sensitive = true }

# NEVER output the secret value
output "secret_name"         { value = google_secret_manager_secret.this.name }
output "secret_version_name" { value = ... }
```

### modules/security/kms

```hcl
variable "key_ring_suffix" { type = string }
variable "keys" {
  type = map(object({
    rotation_period = string   # e.g., "2592000s" (30 days)
    algorithm       = string   # e.g., "GOOGLE_SYMMETRIC_ENCRYPTION"
    purpose         = string   # e.g., "ENCRYPT_DECRYPT"
  }))
}
variable "key_iam_bindings" { type = map(list(string)); default = {} }
variable "prevent_destroy"  { type = bool; default = true }

output "key_ring_id" { value = ... }
output "key_ids"     { value = { for k, _ in var.keys : k => google_kms_crypto_key.keys[k].id } }
```

### modules/security/dlp

```hcl
variable "inspection_template_display_name"  { type = string }
variable "info_types"                         { type = list(string) }
variable "deidentify_template_display_name"  { type = string; default = "" }
variable "deidentify_transformation"         { type = string; default = "REPLACE_WITH_INFO_TYPE" }

output "inspection_template_id"  { value = ... }
output "deidentify_template_id"  { value = var.deidentify_template_display_name != "" ? ... : "" }
```

### modules/governance/dataplex

```hcl
variable "lake_name_suffix" { type = string }
variable "zones" {
  type = map(object({
    type          = string         # "RAW" or "CURATED"
    asset_buckets = list(string)   # GCS bucket names
  }))
}
variable "data_stewards" { type = list(string); default = [] }

output "lake_id"   { value = ... }
output "zone_ids"  { value = { for k, _ in var.zones : k => google_dataplex_zone.zones[k].id } }
```

### modules/data/dataproc

```hcl
variable "cluster_name_suffix"  { type = string }
variable "master_machine_type"  { type = string; default = "n2-standard-4" }
variable "master_disk_gb"       { type = number; default = 100 }
variable "worker_machine_type"  { type = string; default = "n2-standard-8" }
variable "worker_count"         { type = number; default = 2 }
variable "worker_disk_gb"       { type = number; default = 200 }
variable "enable_dr_standby"    { type = bool; default = false }
variable "dr_region"            { type = string; default = "asia-southeast1" }
variable "subnet_name"          { type = string }
variable "service_account"      { type = string; default = "" }
variable "initialization_actions" { type = list(string); default = [] }

output "cluster_name"    { value = ... }
output "cluster_id"      { value = ... }
output "dr_cluster_name" { value = var.enable_dr_standby ? ... : "" }
```

### modules/data/bigquery

```hcl
variable "dataset_id_suffix"          { type = string }
variable "active_table_expiration_ms" { type = number; default = 0 }
variable "delete_contents_on_destroy" { type = bool; default = false }
variable "access_bindings" {
  type = list(object({
    role    = string
    members = list(string)
  }))
  default = []
}

output "dataset_id"        { value = ... }
output "dataset_self_link" { value = ... }
```

### modules/storage/gcs

```hcl
variable "bucket_name_suffix"          { type = string }
variable "unique_suffix"               { type = string }
variable "storage_class"               { type = string; default = "STANDARD" }
variable "versioning_enabled"          { type = bool; default = true }
variable "dr_replication_region"       { type = string; default = "" }
  # validation: dr_replication_region == "" || dr_replication_region != var.region
variable "uniform_bucket_level_access" { type = bool; default = true }
variable "lifecycle_rules" {
  type = list(object({ action = string; age_days = number }))
  default = []
}

output "bucket_name"    { value = ... }
output "bucket_url"     { value = ... }
output "dr_bucket_name" { value = var.dr_replication_region != "" ? ... : "" }
```

### modules/api/api-gateway

```hcl
variable "api_id_suffix"        { type = string }
variable "openapi_spec"         { type = string }
variable "backend_service_url"  { type = string }
variable "gateway_region"       { type = string; default = "" }  # defaults to var.region

output "api_id"           { value = ... }
output "gateway_id"       { value = ... }
output "default_hostname" { value = ... }
```

### modules/api/cloud-endpoints

```hcl
variable "service_name"         { type = string }
variable "grpc_config"          { type = string; default = "" }
variable "openapi_config"       { type = string; default = "" }
variable "protoc_output_base64" { type = string; default = "" }
  # validation: grpc_config != "" || openapi_config != ""

output "service_name" { value = ... }
output "config_id"    { value = ... }
```

### modules/observability/cloud-logging

```hcl
variable "sink_name_suffix"          { type = string }
variable "log_filter"                { type = string; default = "" }
variable "sink_destination_type"     { type = string; default = "logging-bucket" }
  # validation: contains(["logging-bucket", "gcs", "bigquery", "pubsub"], var.sink_destination_type)
variable "sink_destination_id"       { type = string; default = "" }
variable "log_bucket_retention_days" { type = number; default = 30 }
variable "exclusions" {
  type = list(object({ name = string; filter = string; description = string }))
  default = []
}

output "sink_name"            { value = ... }
output "sink_writer_identity" { value = ... }
output "log_bucket_id"        { value = var.sink_destination_type == "logging-bucket" ? ... : "" }
```
