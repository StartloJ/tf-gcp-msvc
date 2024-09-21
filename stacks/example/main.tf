locals {
  vpc_prefix_name   = "example"
  snet_front_prefix = "snet-${local.vpc_prefix_name}-frontdoor"
  snet_gke_prefix   = "snet-${local.vpc_prefix_name}-gke"
  snet_sql_prefix   = "snet-${local.vpc_prefix_name}-sql"
  default_region    = "asia-southeast1"
  available_zones   = ["asia-southeast1-a", "asia-southeast1-b", "asia-southeast1-c"]

  main_ip_subnet                = "10.186.0.0/16"
  public_ip_subnet              = "10.186.0.0/24"
  private_ip_sql_subnet         = "10.186.8.0/24" # Reserved for Cloud SQL allocation
  gke_private_ip_node_subnet    = "10.186.16.0/28"
  gke_private_ip_pod_subnet     = "10.186.219.0/25"
  gke_private_ip_service_subnet = "10.186.16.64/26"
  gke_private_ip_master_subnet  = "10.186.16.16/28"


  gke_app_lb_external_name = "examplelb-ip"

  /**********************************
  default_tags = {
    env         = "dev"
    project     = "example"
    owner       = "cloud_team"
    cost_center = "infrastructure"
  }
  **********************************/
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

  network_name                           = "${local.vpc_prefix_name}-main-vpc"
  routing_mode                           = "GLOBAL"
  shared_vpc_host                        = false
  auto_create_subnetworks                = false
  delete_default_internet_gateway_routes = false
  mtu                                    = 1460
}

/******************************************
        Subnets example card
 *****************************************/
module "example_snet" {
  source = "../../modules/networks/subnets"

  project_id   = data.google_project.example.project_id
  network_name = module.example_main_vpc.network_name
  subnets = [
    {
      subnet_name           = "${local.snet_front_prefix}-public"
      subnet_ip             = local.public_ip_subnet
      subnet_region         = local.default_region
      subnet_private_access = false
      subnet_flow_logs      = false
      description           = "Public access subnet for example Card project"
      stack_type            = "IPV4_ONLY"
    },
    {
      subnet_name           = "${local.snet_gke_prefix}-private"
      subnet_ip             = local.gke_private_ip_node_subnet
      subnet_region         = local.default_region
      subnet_private_access = true
      subnet_flow_logs      = false
      description           = "Private access subnet for GKE apps example Card project"
      stack_type            = "IPV4_ONLY"
    },
    {
      subnet_name           = "${local.snet_sql_prefix}-private"
      subnet_ip             = local.private_ip_sql_subnet
      subnet_region         = local.default_region
      subnet_private_access = true
      subnet_flow_logs      = false
      description           = "Private access subnet for Cloud SQL example Card project"
      stack_type            = "IPV4_ONLY"
    }
  ]

  secondary_ranges = {
    "${local.snet_gke_prefix}-private" = [
      {
        range_name    = "${local.snet_gke_prefix}-private-pods"
        ip_cidr_range = local.gke_private_ip_pod_subnet
      },
      {
        range_name    = "${local.snet_gke_prefix}-private-services"
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
}

/******************************************
        NAT router example card
 *****************************************/
module "example_nat" {
  source = "../../modules/networks/router-nat"

  project_id   = data.google_project.example.project_id
  network_name = module.example_main_vpc.network_name

  region                             = local.default_region
  router                             = "example-cloud-nat"
  create_router                      = true
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
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