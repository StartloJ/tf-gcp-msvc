variable "project_id" {
  type        = string
  description = "The GCP project ID where Dataplex resources will be created."
}

variable "region" {
  type        = string
  description = "The GCP region where the Dataplex lake and zones will be created."
  default     = "asia-southeast1"
}

variable "org" {
  type        = string
  description = "Organisation abbreviation used in resource naming (e.g. obk)."
}

variable "domain" {
  type        = string
  description = "Business domain abbreviation used in resource naming (e.g. ml, data)."
}

variable "env" {
  type        = string
  description = "Environment code used in resource naming. One of: shd, prd, np, sbx."
}

# tflint-ignore: terraform_unused_declarations
variable "region_code" {
  type        = string
  description = "Short region code. Kept for module interface consistency; Dataplex lake naming uses env but not region_code."
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to the Dataplex lake and zones."
  default     = {}
}

variable "lake_name_suffix" {
  type        = string
  description = "Purpose suffix used in lake naming. Full name: lake-<org>-<domain>-<suffix>-<env>."
}

variable "zones" {
  type = map(object({
    type          = string
    asset_buckets = list(string)
  }))
  description = "Map of zone name to configuration. type must be RAW or CURATED. asset_buckets lists GCS bucket names to register as assets."

  validation {
    condition     = alltrue([for z in values(var.zones) : contains(["RAW", "CURATED"], z.type)])
    error_message = "Each zone type must be one of: RAW, CURATED."
  }
}

variable "data_stewards" {
  type        = list(string)
  description = "IAM members granted roles/dataplex.dataOwner on the lake for data governance."
  default     = []
}
