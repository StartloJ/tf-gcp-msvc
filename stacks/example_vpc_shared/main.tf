/*
  Shared VPC Example
  ==================
  Demonstrates Shared VPC in a GCP organization with folder-based IAM.

  GCP Org Folder Structure assumed by this stack
  -----------------------------------------------
  Organization
  ├── Folder: networking  (host_folder_id)
  │   └── host-project   (host_project_id)   ← this stack manages it as VPC host
  │       └── shared-vpc
  │           ├── snet-app-shared
  │           └── snet-data-shared
  └── Folder: services
      ├── service-project-a  (in service_project_ids)
      └── service-project-b  (in service_project_ids)

  IAM delegation chain
  --------------------
  1. roles/compute.xpnAdmin on host_folder_id → network_admin_members
       Allows those identities to configure Shared VPC within the folder.
  2. host_project enrolled as Shared VPC host.
  3. service projects attached to the host.
  4. roles/compute.networkUser per subnet → subnet_users members
       Allows service-project workload identities to use specific subnets.

  Prerequisites
  -------------
  - All projects must already exist under the same GCP organization.
  - network_admin_members and subnet_users members must already exist.
  - The identity running Terraform must have roles/resourcemanager.folderIamAdmin
    on host_folder_id (if using folder IAM), plus roles/compute.networkAdmin
    on host_project_id.
*/

locals {
  # Build a flat list for folder-level xpnAdmin bindings (member → binding key)
  folder_xpn_admin_members = (
    var.host_folder_id != null
    ? { for m in var.network_admin_members : m => m }
    : {}
  )
}

/******************************************
    Folder-level: grant compute.xpnAdmin
    so network admins can manage Shared VPC
    within this folder without org-wide scope
 ******************************************/
resource "google_folder_iam_member" "xpn_admin" {
  for_each = local.folder_xpn_admin_members

  folder = "folders/${var.host_folder_id}"
  role   = "roles/compute.xpnAdmin"
  member = each.value
}

/******************************************
    Shared VPC Host — VPC
 ******************************************/
module "shared_vpc" {
  source = "../../modules/networks/vpc"

  project_id      = var.host_project_id
  network_name    = local.vpc_name
  description     = "Shared VPC owned by host project; subnets delegated to service projects"
  routing_mode    = "GLOBAL"
  shared_vpc_host = true

  # Attach existing service projects so they can use this VPC's subnets.
  service_project_ids = var.service_project_ids

  auto_create_subnetworks                = false
  delete_default_internet_gateway_routes = false
  mtu                                    = 1460
  labels                                 = local.common_labels
}

/******************************************
    Shared Subnets with IAM Delegation
 ******************************************/
module "shared_subnets" {
  source = "../../modules/networks/subnets"

  project_id   = var.host_project_id
  network_name = module.shared_vpc.network_name

  labels = local.common_labels
  subnets = [
    {
      # General application workloads — delegate to all service project SAs
      subnet_name           = "${local.subnet_name}-app"
      subnet_ip             = "10.100.0.0/24"
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Shared subnet for application workloads"
      stack_type            = "IPV4_ONLY"
    },
    {
      # Data-tier workloads — restrict delegation to selected SAs only
      subnet_name           = "${local.subnet_name}-data"
      subnet_ip             = "10.100.1.0/24"
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Shared subnet for data-tier workloads"
      stack_type            = "IPV4_ONLY"
    },
  ]

  # Grant roles/compute.networkUser per subnet.
  # Service project workload SAs listed here can provision resources (VMs,
  # GKE nodes, Cloud SQL PSA) inside the delegated subnets.
  subnet_users = var.subnet_users
}
