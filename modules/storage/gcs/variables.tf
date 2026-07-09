variable "project_id" {
  type        = string
  description = "The GCP project ID where the Cloud Storage bucket will be created."
}

variable "region" {
  type        = string
  description = "The GCP region where the primary bucket will be created."
  default     = "asia-southeast1"
}

variable "org" {
  type        = string
  description = "Organisation abbreviation used in bucket naming (e.g. obk)."
}

variable "domain" {
  type        = string
  description = "Business domain abbreviation used in bucket naming (e.g. ml, data)."
}

variable "env" {
  type        = string
  description = "Environment code used in bucket naming. One of: shd, prd, np, sbx."
}

variable "region_code" {
  type        = string
  description = "Short region code used in bucket naming (e.g. sg for asia-southeast1)."
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all buckets managed by this module."
  default     = {}
}

variable "bucket_name_suffix" {
  type        = string
  description = "Purpose suffix for the bucket name. Full name: bkt-<org>-<domain>-<suffix>-<env>-<region_code>-<unique_suffix>."
}

variable "unique_suffix" {
  type        = string
  description = "Short alphanumeric suffix (4-6 chars) to ensure global bucket name uniqueness. Caller-supplied to keep naming deterministic."
}

variable "storage_class" {
  type        = string
  description = "GCS storage class for the primary bucket."
  default     = "STANDARD"
}

variable "versioning_enabled" {
  type        = bool
  description = "When true, enables object versioning on the primary bucket."
  default     = true
}

variable "dr_replication_region" {
  type        = string
  description = "When non-empty, creates a DR replica bucket in this region and configures cross-bucket replication. Must differ from the primary region."
  default     = ""

  validation {
    condition     = var.dr_replication_region == "" || var.dr_replication_region != var.region
    error_message = "dr_replication_region must differ from the primary region."
  }
}

variable "uniform_bucket_level_access" {
  type        = bool
  description = "When true, enforces uniform bucket-level access (disables per-object ACLs)."
  default     = true
}

variable "lifecycle_rules" {
  type = list(object({
    action   = string
    age_days = number
  }))
  description = "List of age-based lifecycle rules. action is one of: Delete, SetStorageClass."
  default     = []
}
