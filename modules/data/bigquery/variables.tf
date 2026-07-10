variable "project_id" {
  type        = string
  description = "The GCP project ID where the BigQuery dataset will be created."
}

variable "region" {
  type        = string
  description = "The GCP region (location) where the BigQuery dataset will be created."
  default     = "asia-southeast1"
}

# tflint-ignore: terraform_unused_declarations
variable "org" {
  type        = string
  description = "Organisation abbreviation. Kept for module interface consistency; BigQuery dataset IDs use domain/env/region_code without org."
}

variable "domain" {
  type        = string
  description = "Business domain abbreviation used in dataset ID (e.g. ml, data)."
}

variable "env" {
  type        = string
  description = "Environment code used in dataset ID. One of: shd, prd, np, sbx."
}

variable "region_code" {
  type        = string
  description = "Short region code used in dataset ID (e.g. sg for asia-southeast1)."
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to the BigQuery dataset."
  default     = {}
}

variable "dataset_id_suffix" {
  type        = string
  description = "Purpose suffix for the dataset ID. Full ID: ds_<domain>_<suffix>_<env>_<region_code> (underscores)."
}

variable "active_table_expiration_ms" {
  type        = number
  description = "Default table expiration in milliseconds for active storage. Set to 0 for no expiration (long-term)."
  default     = 0
}

variable "delete_contents_on_destroy" {
  type        = bool
  description = "When true, tables and views in the dataset are deleted on destroy. Use with caution in non-sbx environments."
  default     = false
}

variable "access_bindings" {
  type = list(object({
    role    = string
    members = list(string)
  }))
  description = "IAM role bindings for the dataset. Each entry maps a role to a list of IAM members."
  default     = []
}
