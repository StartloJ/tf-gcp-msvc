#####################################
## Classic VPN GCP - GCP to Onprem ##
#####################################
## Ref: https://cloud.google.com/network-connectivity/docs/vpn/how-to/creating-static-vpns#gcloud

module "example_classic_vpn_single" {
  source = "../../modules/networks/vpn-classic"

  project_id         = data.google_project.example.project_id
  network            = module.example_main_vpc.network_name
  region             = local.default_region
  gateway_name       = "example-vpn-gw-to-onprem"
  tunnel_name_prefix = "example-vpn-gw-to-onprem"
  shared_secret      = "c/S;_6:1x3~0PAIG]m!OkD"

  ## Create tunnel with manual, it was about some issue cannot defined policy-based routing with Terraform
  tunnel_count = 1
  peer_ips     = ["8.4.4.8"] # Replace this with your public IP of VPN gateway
  ike_version  = 2

  ## You couldn't leave this value to default as '0.0.0.0/0', because it will be used in route-based routing
  local_traffic_selector  = [local.main_ip_subnet]
  remote_traffic_selector = ["0.0.0.0/0"] # Replace with your internal network CIDR

  route_priority = 1000
  route_type     = "route-based"
  remote_subnet  = ["0.0.0.0/0"] # Replace with your internal network CIDR
}
