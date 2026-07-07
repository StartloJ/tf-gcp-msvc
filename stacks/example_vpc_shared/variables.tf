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
