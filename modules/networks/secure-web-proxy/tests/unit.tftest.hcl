mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id  = "test-prj"
  org         = "test"
  domain      = "ml"
  env         = "np"
  region_code = "sg"
  network_id  = "projects/test-prj/global/networks/test-vpc"
  subnet_cidr = "10.128.0.0/26"
  labels      = { managed_by = "terraform" }
}

run "plan_secure_web_proxy" {
  command = plan

  assert {
    condition     = google_network_services_gateway.this.name == "swp-test-ml-egress-np-sg"
    error_message = "SWP gateway name does not follow naming convention swp-<org>-<domain>-egress-<env>-<region_code>"
  }

  assert {
    condition     = google_network_services_gateway.this.type == "SECURE_WEB_GATEWAY"
    error_message = "Gateway type must be SECURE_WEB_GATEWAY"
  }

  assert {
    condition     = google_compute_subnetwork.proxy.purpose == "REGIONAL_MANAGED_PROXY"
    error_message = "Proxy subnet purpose must be REGIONAL_MANAGED_PROXY"
  }
}

run "plan_swp_with_allow_rules" {
  command = plan

  variables {
    allowed_url_patterns = ["*.googleapis.com", "pypi.org"]
    default_action       = "deny"
  }

  assert {
    condition     = length(google_network_security_gateway_security_policy_rule.allow) == 2
    error_message = "One allow rule should be created per allowed_url_patterns entry"
  }

  assert {
    condition     = length(google_network_security_gateway_security_policy_rule.deny) == 0
    error_message = "No deny rules should be created when denied_url_patterns is empty"
  }
}
