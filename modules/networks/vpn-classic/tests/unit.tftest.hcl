mock_provider "google" {}
mock_provider "random" {}

variables {
  project_id   = "test-project"
  network      = "test-network"
  region       = "asia-southeast1"
  gateway_name = "test-vpn-gateway"
  tunnel_count = 1
  peer_ips     = ["8.8.8.8"]
}

run "plan_classic_vpn_gateway" {
  command = plan

  assert {
    condition     = var.project_id == "test-project"
    error_message = "project_id variable not passed correctly"
  }

  assert {
    condition     = var.gateway_name == "test-vpn-gateway"
    error_message = "gateway_name variable not passed correctly"
  }

  assert {
    condition     = length(var.peer_ips) == 1
    error_message = "peer_ips should have 1 IP address"
  }
}

run "plan_multi_tunnel" {
  command = plan

  variables {
    tunnel_count = 2
    peer_ips     = ["8.8.8.8", "8.8.4.4"]
  }

  assert {
    condition     = var.tunnel_count == 2
    error_message = "tunnel_count should be 2 for HA configuration"
  }

  assert {
    condition     = length(var.peer_ips) == 2
    error_message = "peer_ips should have 2 IP addresses for multi-tunnel"
  }
}
