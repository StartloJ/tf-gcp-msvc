variable "project_id" {
  type        = string
  description = "The GCP project ID where the Cloud Run service will be deployed."
}

variable "region" {
  type        = string
  description = "The GCP region where the Cloud Run service will run."
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
  description = "Environment code used in resource naming and production guard logic. One of: shd, prd, np, sbx."
}

variable "region_code" {
  type        = string
  description = "Short region code used in resource naming (e.g. sg for asia-southeast1)."
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to the Cloud Run service."
  default     = {}
}

variable "service_name_suffix" {
  type        = string
  description = "Purpose suffix for the Cloud Run service name. Full name: cr-<org>-<domain>-<suffix>-<env>-<region_code>."
}

variable "container_image" {
  type        = string
  description = "The container image URI to deploy (e.g. asia-docker.pkg.dev/project/repo/image:tag)."
}

variable "container_port" {
  type        = number
  description = "The port the container listens on."
  default     = 8080
}

variable "cpu" {
  type        = string
  description = "CPU allocation for each container instance (e.g. '1', '2', '1000m')."
  default     = "1"
}

variable "memory" {
  type        = string
  description = "Memory allocation for each container instance (e.g. '512Mi', '2Gi')."
  default     = "512Mi"
}

variable "min_instances" {
  type        = number
  description = "Minimum number of Cloud Run instances (autoscaling floor)."
  default     = 0
}

variable "max_instances" {
  type        = number
  description = "Maximum number of Cloud Run instances (autoscaling ceiling)."
  default     = 10
}

variable "env_vars" {
  type        = map(string)
  description = "Environment variables injected into the container."
  default     = {}
}

variable "allow_unauthenticated" {
  type        = bool
  description = "When true, grants allUsers invoker access. BLOCKED when env == prd — production services must always require authentication."
  default     = false
}

variable "service_account_email" {
  type        = string
  description = "Service account email the Cloud Run service runs as. Leave empty to use the project default compute SA."
  default     = ""
}

variable "vpc_connector_id" {
  type        = string
  description = "Serverless VPC Access connector resource ID for private network egress. Leave empty for public-only access."
  default     = ""
}

variable "ingress_setting" {
  type        = string
  description = "Ingress traffic setting. One of: all, internal, internal-and-cloud-load-balancing."
  default     = "all"

  validation {
    condition     = contains(["all", "internal", "internal-and-cloud-load-balancing"], var.ingress_setting)
    error_message = "ingress_setting must be one of: all, internal, internal-and-cloud-load-balancing."
  }
}
