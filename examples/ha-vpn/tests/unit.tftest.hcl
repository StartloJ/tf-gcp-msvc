mock_provider "google" {}
mock_provider "google-beta" {}

run "plan_ha_vpn_vpc" {
  command = plan

  override_data {
    target = data.google_project.example
    values = {
      project_id = "example-project"
      name       = "example-project"
      number     = "123456789012"
    }
  }

  assert {
    condition     = module.example_main_vpc.network_name == "example-main-vpc"
    error_message = "VPC network name should be example-main-vpc"
  }
}

run "plan_ha_vpn_tunnel_config" {
  command = plan

  override_data {
    target = data.google_project.example
    values = {
      project_id = "example-project"
      name       = "example-project"
      number     = "123456789012"
    }
  }

  override_module {
    target = module.example_vpn_ha_to_onprem
    outputs = {
      name              = "example-vpn"
      gateway           = null
      external_gateway  = null
      router            = null
      router_name       = "example-vpn-router"
      self_link         = ""
      tunnels           = {}
      tunnel_names      = []
      tunnel_self_links = []
      random_secret     = "mock-secret"
    }
  }

  assert {
    condition     = module.example_vpn_ha_to_onprem.name == "example-vpn"
    error_message = "VPN name should be example-vpn"
  }
}
