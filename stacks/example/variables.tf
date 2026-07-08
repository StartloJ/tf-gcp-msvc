variable "org" {
  type        = string
  description = "Organisation abbreviation used in resource naming (e.g. 'obk')."
}

variable "domain" {
  type        = string
  description = "Business domain (e.g. 'platform', 'data', 'connectivity')."
}

variable "env" {
  type        = string
  description = "Deployment environment. Controls resource naming and label value."
  validation {
    condition     = contains(["shd", "prd", "np", "sbx"], var.env)
    error_message = "env must be one of: shd, prd, np, sbx."
  }
}

variable "region_code" {
  type        = string
  description = "Short region code used in resource names. e.g. 'sg' = asia-southeast1, 'th' = asia-southeast2. Must be set explicitly — existing stack uses asia-southeast1 so callers set region_code = \"sg\"."
}

variable "purpose" {
  type        = string
  description = "Workload-specific descriptor used in VPC and NAT names (e.g. 'main', 'lz', 'egress')."
  default     = "main"
}

variable "app" {
  type        = string
  description = "Application or workload identifier for the common_labels map (e.g. 'shared-network')."
}

variable "component" {
  type        = string
  description = "Component identifier for the common_labels map (e.g. 'vpc', 'subnet')."
  default     = "stack"
}

variable "owner_team" {
  type        = string
  description = "Owning team for cost attribution and incident routing (e.g. 'netops', 'platform')."
}

variable "cost_center" {
  type        = string
  description = "Billing cost-center code applied as a label to all resources."
}

variable "data_class" {
  type        = string
  description = "Data classification level applied as a label to all resources."
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted", "na"], var.data_class)
    error_message = "data_class must be one of: public, internal, confidential, restricted, na."
  }
}

variable "artifact_type" {
  type        = string
  description = "Artifact Registry repository format short code used in resource naming (e.g. 'docker', 'maven', 'npm')."
  default     = "docker"
}

variable "db_engine" {
  type        = string
  description = "Database engine short code used in Cloud SQL instance naming (e.g. 'pg' for PostgreSQL, 'mysql')."
  default     = "pg"
}
