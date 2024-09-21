locals {
  vpn_gw_ip = var.vpn_gw_ip == "" ? google_compute_address.vpn_gw_ip[0].address : var.vpn_gw_ip
}
# Assosciate external IP/Port-range to VPN-GW by using Forwarding rules
resource "google_compute_forwarding_rule" "vpn_esp" {
  name        = "${google_compute_vpn_gateway.vpn_gateway.name}-esp"
  ip_protocol = "ESP"
  ip_address  = local.vpn_gw_ip
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  project     = var.project_id
  region      = var.region
}

resource "google_compute_forwarding_rule" "vpn_udp500" {
  name        = "${google_compute_vpn_gateway.vpn_gateway.name}-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = local.vpn_gw_ip
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  project     = var.project_id
  region      = var.region
}

resource "google_compute_forwarding_rule" "vpn_udp4500" {
  name        = "${google_compute_vpn_gateway.vpn_gateway.name}-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = local.vpn_gw_ip
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  project     = var.project_id
  region      = var.region
}