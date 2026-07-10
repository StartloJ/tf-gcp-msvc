variable "project_id" {
  type        = string
  description = "The GCP project ID where Cloud Endpoints will be configured."
}

# tflint-ignore: terraform_unused_declarations
variable "region" {
  type        = string
  description = "The GCP region. Kept for module interface consistency; Cloud Endpoints is a global service."
  default     = "asia-southeast1"
}

# tflint-ignore: terraform_unused_declarations
variable "org" {
  type        = string
  description = "Organisation abbreviation. Kept for module interface consistency; service_name is caller-supplied."
}

# tflint-ignore: terraform_unused_declarations
variable "domain" {
  type        = string
  description = "Business domain abbreviation. Kept for module interface consistency; service_name is caller-supplied."
}

# tflint-ignore: terraform_unused_declarations
variable "env" {
  type        = string
  description = "Environment code. Kept for module interface consistency; service_name is caller-supplied."
}

# tflint-ignore: terraform_unused_declarations
variable "region_code" {
  type        = string
  description = "Short region code. Kept for module interface consistency; service_name is caller-supplied."
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
