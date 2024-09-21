# Static External IP for the VPN Gateway
resource "google_compute_address" "vpn_gw_ip" {
  count   = var.vpn_gw_ip == "" ? 1 : 0
  name    = "ip-${var.gateway_name}"
  region  = var.region
  project = var.project_id
}

# VPN Gateways
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.gateway_name
  network = var.network
  region  = var.region
  project = var.project_id
}