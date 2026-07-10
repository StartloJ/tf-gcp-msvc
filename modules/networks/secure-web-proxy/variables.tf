variable "project_id" {
  type        = string
  description = "The GCP project ID where the Secure Web Proxy will be created."
}

variable "region" {
  type        = string
  description = "The GCP region where the Secure Web Proxy will be deployed."
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
  description = "Labels for this module. Note: SWP gateway resources do not support labels in provider v7."
  default     = {}
}

variable "network_id" {
  type        = string
  description = "The VPC network self_link where the Secure Web Proxy will be deployed."
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range for the proxy-only subnet created for the Secure Web Proxy. Must not overlap with other subnets in the VPC."
}

variable "allowed_url_patterns" {
  type        = list(string)
  description = "List of FQDN or URL patterns that are explicitly allowed. Example: *.googleapis.com, pypi.org."
  default     = []
}

variable "denied_url_patterns" {
  type        = list(string)
  description = "List of FQDN or URL patterns that are explicitly denied."
  default     = []
}

# tflint-ignore: terraform_unused_declarations
variable "default_action" {
  type        = string
  description = "Default action for traffic that does not match any explicit rule. deny (recommended for enterprise) or allow. Reserved for future default-rule implementation."
  default     = "deny"

  validation {
    condition     = contains(["allow", "deny"], var.default_action)
    error_message = "default_action must be one of: allow, deny."
  }
}

variable "enable_tls_inspection" {
  type        = bool
  description = "When true, enables TLS inspection on the Secure Web Proxy. Requires certificate_map_id."
  default     = false
}

variable "certificate_map_id" {
  type        = string
  description = "Certificate Map resource ID for TLS inspection. Required when enable_tls_inspection is true."
  default     = ""
}
