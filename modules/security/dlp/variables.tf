variable "project_id" {
  type        = string
  description = "The GCP project ID where DLP templates will be created."
}

variable "region" {
  type        = string
  description = "The GCP region where DLP templates will be created."
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

variable "region_code" {
  type        = string
  description = "Short region code used in resource naming (e.g. sg for asia-southeast1)."
}

# tflint-ignore: terraform_unused_declarations
variable "labels" {
  type        = map(string)
  description = "Labels for this module. Note: Cloud DLP template resources do not support the labels attribute in provider v7."
  default     = {}
}

variable "inspection_template_display_name" {
  type        = string
  description = "Human-readable display name for the DLP inspection template."
}

variable "info_types" {
  type        = list(string)
  description = "List of DLP info type names to inspect for (e.g. EMAIL_ADDRESS, CREDIT_CARD_NUMBER)."
}

variable "deidentify_template_display_name" {
  type        = string
  description = "Human-readable display name for the DLP de-identification template. Leave empty to skip de-identification template creation."
  default     = ""
}

variable "deidentify_transformation" {
  type        = string
  description = "Primitive transformation type for de-identification. Supported value: REPLACE_WITH_INFO_TYPE."
  default     = "REPLACE_WITH_INFO_TYPE"
}
