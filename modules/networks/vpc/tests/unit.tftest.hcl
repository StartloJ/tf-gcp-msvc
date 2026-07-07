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

run "plan_shared_vpc_host_with_service_projects" {
  command = plan

  variables {
    shared_vpc_host     = true
    service_project_ids = ["service-project-a", "service-project-b"]
  }

  assert {
    condition     = var.shared_vpc_host == true
    error_message = "shared_vpc_host should be true"
  }

  assert {
    condition     = length(var.service_project_ids) == 2
    error_message = "Expected 2 service project IDs"
  }

  assert {
    condition     = length(google_compute_shared_vpc_service_project.service_projects) == 2
    error_message = "Expected 2 google_compute_shared_vpc_service_project resources"
  }
}

run "plan_shared_vpc_host_without_service_projects" {
  command = plan

  variables {
    shared_vpc_host     = true
    service_project_ids = []
  }

  assert {
    condition     = length(google_compute_shared_vpc_service_project.service_projects) == 0
    error_message = "No service projects should be attached when list is empty"
  }
}
