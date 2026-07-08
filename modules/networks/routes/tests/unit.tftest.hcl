mock_provider "google" {}

variables {
  project_id   = "test-project"
  network_name = "test-network"
  routes       = []
  labels       = { managed_by = "terraform" }
}

run "plan_with_no_routes" {
  command = plan

  assert {
    condition     = var.project_id == "test-project"
    error_message = "project_id variable not passed correctly"
  }

  assert {
    condition     = var.network_name == "test-network"
    error_message = "network_name variable not passed correctly"
  }

  assert {
    condition     = length(var.routes) == 0
    error_message = "Expected empty routes list"
  }
}

run "plan_with_routes" {
  command = plan

  variables {
    routes = [
      {
        name              = "egress-internet"
        destination_range = "0.0.0.0/0"
        next_hop_internet = "true"
      }
    ]
  }

  assert {
    condition     = length(var.routes) == 1
    error_message = "Expected 1 route"
  }
}
