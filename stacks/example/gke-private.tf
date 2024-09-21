locals {
  gke_freeze_version            = "1.30.3-gke.1639000"
  gke_node_subnet_name          = module.example_snet.subnets["${local.default_region}/${local.snet_gke_prefix}-private"].name
  gke_pods_subnet_name          = "${local.snet_gke_prefix}-private-pods"
  gke_services_subnet_name      = "${local.snet_gke_prefix}-private-services"
  gke_service_account_node_pool = "example-dev-admin"
}

data "google_client_config" "dev" {}

/********************************************************************************
 * GKE private cluster
  Issues:
  - GKE private can not pull image from Artifact Registry: https://cloud.google.com/kubernetes-engine/docs/troubleshooting?_gl=1*1pp70nx*_ga*ODIyNjc0NzE5LjE3MjIxMDY4NDE.*_ga_WH2QY8WWF5*MTcyNjM5NTc2MC4zOC4xLjE3MjY0MDU0ODEuMjMuMC4w#ImagePullBackOff
  
********************************************************************************/

module "example-gke-private" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 32.0"

  project_id        = data.google_project.example.project_id
  name              = "example-gke-private"
  region            = local.default_region
  zones             = local.available_zones
  network           = module.example_main_vpc.network_name
  subnetwork        = local.gke_node_subnet_name
  ip_range_pods     = local.gke_pods_subnet_name
  ip_range_services = local.gke_services_subnet_name

  create_service_account    = true
  kubernetes_version        = local.gke_freeze_version
  release_channel           = "STABLE"
  service_account_name      = local.gke_service_account_node_pool
  enable_private_endpoint   = false
  enable_private_nodes      = true
  master_ipv4_cidr_block    = local.gke_private_ip_master_subnet
  default_max_pods_per_node = 16
  remove_default_node_pool  = true
  deletion_protection       = false
  network_policy            = false

  grant_registry_access = true

  node_pools = [
    {
      name              = "example-dev-node-pool"
      min_count         = 1
      max_count         = 4
      node_count        = 2
      machine_type      = "e2-standard-4"
      disk_size_gb      = 100
      disk_type         = "pd-standard"
      image_type        = "COS_CONTAINERD"
      auto_repair       = true
      auto_upgrade      = true
      preemptible       = true
      max_pods_per_node = 16
    }
  ]

  master_authorized_networks = [
    {
      cidr_block   = local.main_ip_subnet
      display_name = "default-vpc-allow-controller"
    },
    {
      cidr_block   = "${chomp(data.http.my_public_ip.response_body)}/32"
      display_name = "allow-my-public-ip"
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
    ]
  }

  node_pools_labels = {
    all = {}

    example-dev-node-pool = {
      env       = "dev"
      node_type = "default"
    }
  }

}
