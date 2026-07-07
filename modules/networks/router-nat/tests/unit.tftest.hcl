mock_provider "google" {}
mock_provider "random" {}

variables {
  project_id                         = "test-project"
  network_name                       = "test-network"
  region                             = "asia-southeast1"
  router                             = "test-router"
  create_router                      = true
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

run "plan_cloud_nat_with_auto_router" {
  command = plan

  assert {
    condition     = var.project_id == "test-project"
    error_message = "project_id variable not passed correctly"
  }

  assert {
    condition     = var.region == "asia-southeast1"
    error_message = "region variable not passed correctly"
  }

  assert {
    condition     = var.create_router == true
    error_message = "create_router should be true"
  }
}

run "plan_cloud_nat_existing_router" {
  command = plan

  variables {
    create_router = false
  }

  assert {
    condition     = var.create_router == false
    error_message = "create_router should be false when using existing router"
  }
}
