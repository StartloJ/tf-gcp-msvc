variable "project_id" {
  type        = string
  description = "The GCP project ID where the API Gateway will be created."
}

variable "region" {
  type        = string
  description = "The GCP region where the API Gateway will be deployed."
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
  description = "Labels for this module. Note: API Gateway resources have limited label support in provider v7."
  default     = {}
}

variable "api_id_suffix" {
  type        = string
  description = "Suffix for the API resource ID. Full ID: apig-<org>-<domain>-<suffix>-<env>."
}

variable "openapi_spec" {
  type        = string
  description = "The OpenAPI 2.0 or 3.0 specification content as a YAML or JSON string."
}

variable "gateway_config_id_suffix" {
  type        = string
  description = "Suffix for the gateway config resource ID. Full ID: apigc-<org>-<domain>-<suffix>-<env>."
}

variable "service_account_email" {
  type        = string
  description = "Service account email for backend authentication. Required when OpenAPI spec contains x-google-backend directives."
  default     = ""
}
