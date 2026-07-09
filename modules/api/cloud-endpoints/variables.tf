variable "project_id" {
  type        = string
  description = "The GCP project ID where Cloud Endpoints will be configured."
}

variable "region" {
  type        = string
  description = "The GCP region. Used as a label/annotation in resource naming."
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
  description = "Labels for this module. Note: Cloud Endpoints service resources do not support labels in provider v7."
  default     = {}
}

variable "service_name" {
  type        = string
  description = "The fully-qualified Cloud Endpoints service name (e.g. my-api.endpoints.project.cloud.goog)."
}

variable "openapi_spec" {
  type        = string
  description = "The OpenAPI 2.0 specification content as a YAML string with x-google-backend extensions."
}

variable "iam_consumers" {
  type        = list(string)
  description = "IAM members granted roles/servicemanagement.serviceConsumer on the endpoint service."
  default     = []
}
