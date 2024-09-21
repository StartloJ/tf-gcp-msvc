module "example_main_vpc" {
  source = "../../modules/networks/vpc"

  project_id  = "example-project"
  description = "VPC for example"

  network_name                           = "example-main-vpc"
  routing_mode                           = "GLOBAL"
  shared_vpc_host                        = false
  auto_create_subnetworks                = false
  delete_default_internet_gateway_routes = false
  mtu                                    = 1460
}

module "example_snet" {
  source = "../../modules/networks/subnets"

  project_id   = data.google_project.example.project_id
  network_name = module.example_main_vpc.network_name
  subnets = [
    {
      subnet_name           = "example-public"
      subnet_ip             = "10.0.0.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = false
      subnet_flow_logs      = false
      description           = "Public access subnet for example"
      stack_type            = "IPV4_ONLY"
    }
  ]
}

module "example_vpn_ha_to_onprem" {
  source = "../../modules/networks/vpn-ha"

  project_id = "example-project"
  name       = "example-vpn"
  network    = module.example_main_vpc.network_name
  region     = "us-central1"
  router_asn = 64513

  peer_external_gateway = {
    redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
    interfaces = [
      {
        id         = 0
        ip_address = "8.8.8.8" # onprem vpn gateway IP
      }
    ]
  }

  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2" # onprem vpn gateway peer interface IP
        asn     = 64515
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = 0
      shared_secret                   = ""
    }
  }
}