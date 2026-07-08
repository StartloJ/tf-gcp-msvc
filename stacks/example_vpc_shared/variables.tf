variable "host_project_id" {
  type        = string
  description = "Project ID of the Shared VPC host project. This project owns the VPC and subnets. Must already exist in host_folder_id."
}

variable "service_project_ids" {
  type        = list(string)
  description = "List of existing service project IDs to attach to the Shared VPC host. All projects must already exist under the same GCP organization. Typically these live in a separate services folder."
  default     = []
}

variable "region" {
  type        = string
  description = "Default GCP region for subnets."
  default     = "asia-southeast1"
}

variable "subnet_users" {
  type        = map(list(string))
  description = "Map of subnet name to list of IAM members granted roles/compute.networkUser on that subnet. Typically the Compute Engine default SA or a workload identity SA from each service project. Members must already exist."
  default     = {}
  # Example:
  # subnet_users = {
  #   "snet-app-shared" = [
  #     "serviceAccount:111-compute@developer.gserviceaccount.com",
  #     "serviceAccount:222-compute@developer.gserviceaccount.com",
  #   ]
  #   "snet-data-shared" = [
  #     "serviceAccount:111-compute@developer.gserviceaccount.com",
  #   ]
  # }
}

# ---------------------------------------------------------------------------
# GCP Organization / Folder context
# ---------------------------------------------------------------------------
# Shared VPC spans multiple GCP org folders. Granting roles/compute.xpnAdmin
# at the folder level (rather than org level) limits blast radius: only
# projects within host_folder_id can be configured as Shared VPC hosts.

variable "host_folder_id" {
  type        = string
  description = "GCP folder ID (numeric, e.g. '123456789012') that contains the host project. Used to grant roles/compute.xpnAdmin to network_admin_members at the folder level."
  default     = null
}

variable "network_admin_members" {
  type        = list(string)
  description = "IAM members granted roles/compute.xpnAdmin on host_folder_id. These identities can enable and configure Shared VPC within the folder. Only used when host_folder_id is set. Must already exist."
  default     = []
  # Example:
  # network_admin_members = [
  #   "group:network-admins@example.com",
  #   "serviceAccount:terraform@my-host-project.iam.gserviceaccount.com",
  # ]
}

# ---------------------------------------------------------------------------
# Naming token and label variables (US5 — naming convention & label policy)
# ---------------------------------------------------------------------------

variable "org" {
  type        = string
  description = "Organisation abbreviation used in resource naming (e.g. 'obk')."
}

variable "domain" {
  type        = string
  description = "Business domain (e.g. 'platform', 'connectivity')."
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
  description = "Short region code used in resource names (e.g. 'sg' = asia-southeast1)."
}

variable "purpose" {
  type        = string
  description = "Workload-specific descriptor used in VPC names (e.g. 'shared', 'lz')."
  default     = "shared"
}

variable "app" {
  type        = string
  description = "Application or workload identifier for the common_labels map."
}

variable "component" {
  type        = string
  description = "Component identifier for the common_labels map."
  default     = "shared-vpc"
}

variable "owner_team" {
  type        = string
  description = "Owning team for cost attribution and incident routing."
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
