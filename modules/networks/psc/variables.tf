variable "project_id" {
  type        = string
  description = "The GCP project ID where the PSC consumer endpoint will be created."
}

variable "region" {
  type        = string
  description = "The GCP region for service-attachment type PSC endpoints."
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
  description = "Labels for this module. Note: forwarding rule resources do not consistently support labels in provider v7."
  default     = {}
}

variable "network_id" {
  type        = string
  description = "The VPC network self_link to create the PSC consumer endpoint in."
}

variable "subnet_id" {
  type        = string
  description = "The subnet self_link for the PSC consumer endpoint. Required when psc_type is service-attachment."
  default     = ""
}

variable "psc_type" {
  type        = string
  description = "PSC pattern to use. google-apis: creates a bundle endpoint for all googleapis.com services. service-attachment: creates an endpoint for a specific service."
  default     = "google-apis"

  validation {
    condition     = contains(["google-apis", "service-attachment"], var.psc_type)
    error_message = "psc_type must be one of: google-apis, service-attachment."
  }
}

variable "service_attachment_uri" {
  type        = string
  description = "The service attachment URI for the PSC target. Required when psc_type is service-attachment."
  default     = ""

  validation {
    condition     = var.psc_type != "service-attachment" || var.service_attachment_uri != ""
    error_message = "service_attachment_uri is required when psc_type is service-attachment."
  }
}

variable "create_dns_zone" {
  type        = bool
  description = "When true (default) and psc_type is google-apis, creates a private DNS zone for googleapis.com and a wildcard A record pointing to the PSC endpoint IP."
  default     = true
}
