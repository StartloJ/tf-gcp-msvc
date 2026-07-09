mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id  = "test-prj"
  org         = "test"
  domain      = "ml"
  env         = "np"
  region_code = "sg"
  backend_service_backends = [
    {
      group          = "projects/test-prj/regions/asia-southeast1/networkEndpointGroups/my-neg"
      balancing_mode = "RATE"
    }
  ]
  labels = { managed_by = "terraform" }
}

run "plan_external_global_lb" {
  command = plan

  variables {
    load_balancer_type      = "external-global"
    ssl_certificate_domains = ["app.example.com"]
  }

  assert {
    condition     = length(google_compute_backend_service.global) == 1
    error_message = "Global backend service should be created for external-global type"
  }

  assert {
    condition     = google_compute_backend_service.global[0].load_balancing_scheme == "EXTERNAL_MANAGED"
    error_message = "External global LB backend should use EXTERNAL_MANAGED scheme"
  }

  assert {
    condition     = length(google_compute_global_forwarding_rule.global) == 1
    error_message = "Global forwarding rule should be created for external-global type"
  }

  assert {
    condition     = length(google_compute_forwarding_rule.regional) == 0
    error_message = "Regional forwarding rule should not be created for external-global type"
  }
}

run "plan_internal_regional_lb" {
  command = plan

  variables {
    load_balancer_type = "internal-regional"
    network_id         = "projects/test-prj/global/networks/test-vpc"
    subnet_id          = "projects/test-prj/regions/asia-southeast1/subnetworks/test-subnet"
  }

  assert {
    condition     = length(google_compute_region_backend_service.regional) == 1
    error_message = "Regional backend service should be created for internal-regional type"
  }

  assert {
    condition     = google_compute_region_backend_service.regional[0].load_balancing_scheme == "INTERNAL_MANAGED"
    error_message = "Internal regional LB backend should use INTERNAL_MANAGED scheme"
  }

  assert {
    condition     = length(google_compute_forwarding_rule.regional) == 1
    error_message = "Regional forwarding rule should be created for internal-regional type"
  }
}
