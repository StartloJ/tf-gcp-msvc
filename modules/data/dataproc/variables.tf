variable "project_id" {
  type        = string
  description = "The GCP project ID where the Dataproc cluster will be created."
}

variable "region" {
  type        = string
  description = "The GCP region where the primary Dataproc cluster will be created."
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

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources managed by this module."
  default     = {}
}

variable "cluster_name_suffix" {
  type        = string
  description = "Purpose suffix used in cluster naming. Full name: dpc-<org>-<domain>-<suffix>-<env>-<region_code>-01."
}

variable "master_machine_type" {
  type        = string
  description = "Machine type for the Dataproc master node."
  default     = "n2-standard-4"
}

variable "master_disk_gb" {
  type        = number
  description = "Boot disk size in GB for the master node."
  default     = 100
}

variable "worker_machine_type" {
  type        = string
  description = "Machine type for Dataproc worker nodes."
  default     = "n2-standard-8"
}

variable "worker_count" {
  type        = number
  description = "Number of primary worker nodes."
  default     = 2
}

variable "worker_disk_gb" {
  type        = number
  description = "Boot disk size in GB for each worker node."
  default     = 200
}

variable "enable_dr_standby" {
  type        = bool
  description = "When true, provisions a standby Dataproc cluster in dr_region for disaster recovery."
  default     = false
}

variable "dr_region" {
  type        = string
  description = "GCP region for the DR standby cluster. Must differ from the primary region."
  default     = "asia-southeast1"
}

variable "subnet_name" {
  type        = string
  description = "The name of the VPC subnet to attach the Dataproc cluster to."
}

variable "service_account" {
  type        = string
  description = "Service account email for Dataproc cluster nodes. Uses the Compute Engine default if empty."
  default     = ""
}

variable "initialization_actions" {
  type        = list(string)
  description = "List of GCS URIs of init action scripts to run on cluster nodes at startup."
  default     = []
}
