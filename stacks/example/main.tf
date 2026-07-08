locals {
  default_region  = "asia-southeast1"
  available_zones = ["asia-southeast1-a", "asia-southeast1-b", "asia-southeast1-c"]

  main_ip_subnet                = "10.186.0.0/16"
  public_ip_subnet              = "10.186.0.0/24"
  private_ip_sql_subnet         = "10.186.8.0/24"
  gke_private_ip_node_subnet    = "10.186.16.0/28"
  gke_private_ip_pod_subnet     = "10.186.219.0/25"
  gke_private_ip_service_subnet = "10.186.16.64/26"
  gke_private_ip_master_subnet  = "10.186.16.16/28"

  # Subnet names composed from naming locals in locals.tf
  snet_front_name = "${local.subnet_name}-frontdoor-public"
  snet_gke_name   = "${local.subnet_name}-gke-private"
  snet_sql_name   = "${local.subnet_name}-sql-private"

  gke_app_lb_external_name = "examplelb-ip"
}

data "http" "my_public_ip" {
  url = "https://ifconfig.co/ip"
}

data "google_project" "example" {
}

/******************************************
	      VPC example card
 *****************************************/
module "example_main_vpc" {
  source = "../../modules/networks/vpc"

  project_id  = data.google_project.example.project_id
  description = "VPC for Non production example Card project"

  network_name                           = local.vpc_name
  routing_mode                           = "GLOBAL"
  shared_vpc_host                        = false
  auto_create_subnetworks                = false
  delete_default_internet_gateway_routes = false
  mtu                                    = 1460
  labels                                 = local.common_labels
}

/******************************************
        Subnets example card
 *****************************************/
module "example_snet" {
  source = "../../modules/networks/subnets"

  project_id   = data.google_project.example.project_id
  network_name = module.example_main_vpc.network_name
  labels       = local.common_labels
  subnets = [
    {
      subnet_name           = local.snet_front_name
      subnet_ip             = local.public_ip_subnet
      subnet_region         = local.default_region
      subnet_private_access = false
      subnet_flow_logs      = false
      description           = "Public access subnet for example Card project"
      stack_type            = "IPV4_ONLY"
    },
    {
      subnet_name           = local.snet_gke_name
      subnet_ip             = local.gke_private_ip_node_subnet
      subnet_region         = local.default_region
      subnet_private_access = true
      subnet_flow_logs      = false
      description           = "Private access subnet for GKE apps example Card project"
      stack_type            = "IPV4_ONLY"
    },
    {
      subnet_name           = local.snet_sql_name
      subnet_ip             = local.private_ip_sql_subnet
      subnet_region         = local.default_region
      subnet_private_access = true
      subnet_flow_logs      = false
      description           = "Private access subnet for Cloud SQL example Card project"
      stack_type            = "IPV4_ONLY"
    }
  ]

  secondary_ranges = {
    (local.snet_gke_name) = [
      {
        range_name    = "${local.snet_gke_name}-pods"
        ip_cidr_range = local.gke_private_ip_pod_subnet
      },
      {
        range_name    = "${local.snet_gke_name}-services"
        ip_cidr_range = local.gke_private_ip_service_subnet
      }
    ]
  }
}

/******************************************
        Routing example card
 *****************************************/
module "example_routes" {
  source = "../../modules/networks/routes"

  project_id   = data.google_project.example.project_id
  network_name = module.example_main_vpc.network_name
  routes       = []
  labels       = local.common_labels
}

/******************************************
        NAT router example card
 *****************************************/
module "example_nat" {
  source = "../../modules/networks/router-nat"

  project_id   = data.google_project.example.project_id
  network_name = module.example_main_vpc.network_name

  region                             = local.default_region
  router                             = local.router_name
  name                               = local.nat_name
  create_router                      = true
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  labels                             = local.common_labels
}

/******************************************
        Public IP example card
 *****************************************/
# data "google_compute_address" "gke_app_lb_ip" {
#   name = local.gke_app_lb_external_name
# }
resource "google_compute_address" "gke_app_lb_ip" {
  name    = local.gke_app_lb_external_name
  project = data.google_project.example.project_id
  region  = local.default_region
}