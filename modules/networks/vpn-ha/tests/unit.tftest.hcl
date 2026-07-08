mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "random" {}

variables {
  name        = "test-ha-vpn"
  project_id  = "test-project"
  network     = "test-network"
  region      = "asia-southeast1"
  router_name = ""
  tunnels     = {}
  labels      = { managed_by = "terraform" }
}

run "plan_ha_vpn_no_tunnels" {
  command = plan

  assert {
    condition     = var.name == "test-ha-vpn"
    error_message = "name variable not passed correctly"
  }

  assert {
    condition     = var.project_id == "test-project"
    error_message = "project_id variable not passed correctly"
  }

  assert {
    condition     = length(var.tunnels) == 0
    error_message = "Expected empty tunnels map"
  }
}

run "plan_ha_vpn_with_peer_gcp" {
  command = plan

  variables {
    peer_gcp_gateway = "projects/peer-project/regions/asia-southeast1/vpnGateways/peer-gw"
  }

  assert {
    condition     = var.peer_gcp_gateway != null
    error_message = "peer_gcp_gateway should be set"
  }
}
