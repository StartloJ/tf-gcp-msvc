locals {
  tunnel_name_prefix    = var.tunnel_name_prefix != "" ? var.tunnel_name_prefix : "${var.network}-${var.gateway_name}-tunnel"
  default_shared_secret = var.shared_secret != "" ? var.shared_secret : random_id.ipsec_secret.b64_url
}

# For VPN gateways with static routing
## Create Route (for static routing gateways)
resource "google_compute_route" "route" {
  count      = !var.cr_enabled && var.route_type == "route-based" ? var.tunnel_count * length(var.remote_subnet) : 0
  name       = "${google_compute_vpn_gateway.vpn_gateway.name}-tunnel${floor(count.index / length(var.remote_subnet)) + 1}-route${count.index % length(var.remote_subnet) + 1}"
  network    = var.network
  project    = var.project_id
  dest_range = var.remote_subnet[count.index % length(var.remote_subnet)]
  priority   = var.route_priority
  tags       = var.route_tags

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel-static[floor(count.index / length(var.remote_subnet))].self_link

  depends_on = [google_compute_vpn_tunnel.tunnel-static]
}

# For VPN gateways with policy routing
## Create Route (for static routing gateways)
resource "google_network_connectivity_policy_based_route" "route-policy" {
  count = !var.cr_enabled && var.route_type == "policy-based" ? var.tunnel_count * length(var.remote_subnet) : 0

  name     = "${google_compute_vpn_gateway.vpn_gateway.name}-tunnel${floor(count.index / length(var.remote_subnet)) + 1}-route${count.index % length(var.remote_subnet) + 1}"
  network  = "projects/${var.project_id}/global/networks/${var.network}"
  project  = var.project_id
  priority = var.route_priority

  filter {
    protocol_version = "IPV4"
    ip_protocol      = "ALL"
    src_range        = var.local_subnet[count.index % length(var.local_subnet)] != null ? var.local_subnet[count.index % length(var.local_subnet)] : "0.0.0.0/0"
    dest_range       = var.remote_subnet[count.index % length(var.remote_subnet)] != null ? var.remote_subnet[count.index % length(var.remote_subnet)] : "0.0.0.0/0"
  }

  # next_hop_ilb_ip = google_compute_vpn_tunnel.tunnel-static[floor(count.index / length(var.remote_subnet))].vpn_gateway
  next_hop_other_routes = "DEFAULT_ROUTING"

  depends_on = [google_compute_vpn_tunnel.tunnel-static]
}


# For VPN gateways routing through BGP and Cloud Routers
## Create Router Interfaces
resource "google_compute_router_interface" "router_interface" {
  count      = var.cr_enabled ? var.tunnel_count : 0
  name       = "interface-${local.tunnel_name_prefix}-${count.index}"
  router     = var.cr_name
  region     = var.region
  ip_range   = var.bgp_cr_session_range[count.index]
  vpn_tunnel = google_compute_vpn_tunnel.tunnel-dynamic[count.index].name
  project    = var.project_id

  depends_on = [google_compute_vpn_tunnel.tunnel-dynamic]
}

## Create Peers
resource "google_compute_router_peer" "bgp_peer" {
  count                     = var.cr_enabled ? var.tunnel_count : 0
  name                      = "bgp-session-${local.tunnel_name_prefix}-${count.index}"
  router                    = var.cr_name
  region                    = var.region
  peer_ip_address           = var.bgp_remote_session_range[count.index]
  peer_asn                  = var.peer_asn[count.index]
  advertised_route_priority = var.advertised_route_priority
  interface                 = "interface-${local.tunnel_name_prefix}-${count.index}"
  project                   = var.project_id

  depends_on = [google_compute_router_interface.router_interface]
}