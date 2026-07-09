variable "project_id" {
  type        = string
  description = "The GCP project ID where the load balancer will be created."
}

variable "region" {
  type        = string
  description = "The GCP region for internal-regional load balancers."
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
  description = "Labels for this module. Note: load balancer resources support labels selectively in provider v7."
  default     = {}
}

variable "load_balancer_type" {
  type        = string
  description = "Type of load balancer to create. external-global: external HTTPS global ALB. internal-regional: internal HTTPS regional ILB."
  default     = "external-global"

  validation {
    condition     = contains(["external-global", "internal-regional"], var.load_balancer_type)
    error_message = "load_balancer_type must be one of: external-global, internal-regional."
  }
}

variable "backend_service_backends" {
  type = list(object({
    group           = string
    balancing_mode  = string
    capacity_scaler = optional(number, 1.0)
  }))
  description = "List of backend configurations. group is the NEG or instance group self_link. balancing_mode is UTILIZATION or RATE."
}

variable "ssl_certificate_domains" {
  type        = list(string)
  description = "Domains for a Google-managed SSL certificate (external-global only). Leave empty to use custom_ssl_certificate_id."
  default     = []
}

variable "custom_ssl_certificate_id" {
  type        = string
  description = "Self-managed SSL certificate resource ID. Takes precedence over ssl_certificate_domains when set."
  default     = ""
}

variable "url_map_rules" {
  type = list(object({
    path_prefix        = string
    backend_service_id = string
  }))
  description = "List of path-based routing rules for the URL map."
  default     = []
}

variable "health_check_path" {
  type        = string
  description = "HTTP path for the backend health check."
  default     = "/healthz"
}

variable "network_id" {
  type        = string
  description = "VPC network self_link for internal-regional load balancers."
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "Subnet self_link for internal-regional load balancers."
  default     = ""
}
