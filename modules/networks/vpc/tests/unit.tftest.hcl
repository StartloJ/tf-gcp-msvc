mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id   = "test-project"
  network_name = "test-vpc"
}

run "plan_basic_vpc" {
  command = plan

  assert {
    condition     = var.network_name == "test-vpc"
    error_message = "network_name variable not passed correctly"
  }

  assert {
    condition     = var.project_id == "test-project"
    error_message = "project_id variable not passed correctly"
  }
}

run "plan_vpc_with_custom_routing" {
  command = plan

  variables {
    routing_mode            = "REGIONAL"
    auto_create_subnetworks = false
    shared_vpc_host         = false
  }

  assert {
    condition     = var.routing_mode == "REGIONAL"
    error_message = "routing_mode not set correctly"
  }

  assert {
    condition     = var.auto_create_subnetworks == false
    error_message = "auto_create_subnetworks should be false"
  }
}
