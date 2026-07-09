mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id  = "test-prj"
  org         = "test"
  domain      = "ml"
  env         = "np"
  region_code = "sg"
  network_id  = "projects/test-prj/global/networks/test-vpc"
  labels      = { managed_by = "terraform" }
}

run "plan_psc_google_apis" {
  command = plan

  variables {
    psc_type = "google-apis"
  }

  assert {
    condition     = google_compute_global_address.psc_googleapis[0].purpose == "PRIVATE_SERVICE_CONNECT"
    error_message = "PSC address purpose must be PRIVATE_SERVICE_CONNECT"
  }

  assert {
    condition     = google_compute_global_forwarding_rule.psc_googleapis[0].target == "all-apis"
    error_message = "PSC forwarding rule target must be all-apis for google-apis type"
  }

  assert {
    condition     = length(google_dns_managed_zone.psc_googleapis) == 1
    error_message = "DNS zone should be created by default when psc_type is google-apis"
  }

  assert {
    condition     = length(google_compute_address.psc_service) == 0
    error_message = "Regional PSC address should not be created for google-apis type"
  }
}

run "plan_psc_service_attachment" {
  command = plan

  variables {
    psc_type               = "service-attachment"
    subnet_id              = "projects/test-prj/regions/asia-southeast1/subnetworks/test-subnet"
    service_attachment_uri = "projects/svc-prj/regions/asia-southeast1/serviceAttachments/my-svc"
  }

  assert {
    condition     = length(google_compute_forwarding_rule.psc_service) == 1
    error_message = "Regional PSC forwarding rule should be created for service-attachment type"
  }

  assert {
    condition     = length(google_compute_global_address.psc_googleapis) == 0
    error_message = "Global PSC address should not be created for service-attachment type"
  }
}
