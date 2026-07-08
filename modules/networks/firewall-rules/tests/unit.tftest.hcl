mock_provider "google" {}

variables {
  project_id   = "test-project"
  network_name = "test-network"
  labels       = { managed_by = "terraform" }
  ingress_rules = [
    {
      name          = "allow-http"
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
    },
    {
      name          = "allow-health-check"
      source_ranges = ["35.191.0.0/16"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["8080"]
        }
      ]
    }
  ]
}

run "plan_with_two_ingress_rules" {
  command = plan

  assert {
    condition     = length(var.ingress_rules) == 2
    error_message = "Expected 2 ingress rules to be provided"
  }

  assert {
    condition     = var.project_id == "test-project"
    error_message = "project_id variable not passed correctly"
  }

  assert {
    condition     = var.network_name == "test-network"
    error_message = "network_name variable not passed correctly"
  }
}

run "plan_with_empty_rules" {
  command = plan

  variables {
    ingress_rules = []
    egress_rules  = []
  }

  assert {
    condition     = length(var.ingress_rules) == 0
    error_message = "Expected empty ingress_rules"
  }
}
