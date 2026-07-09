mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id               = "test-prj"
  org                      = "test"
  domain                   = "ml"
  env                      = "np"
  region_code              = "sg"
  api_id_suffix            = "inference"
  gateway_config_id_suffix = "inference"
  openapi_spec             = "openapi: \"2.0\"\ninfo:\n  title: Test API\n  version: 1.0.0\npaths: {}"
  labels                   = { managed_by = "terraform" }
}

run "plan_api_gateway" {
  command = plan

  assert {
    condition     = google_api_gateway_api.this.api_id == "apig-test-ml-inference-np"
    error_message = "API ID does not follow naming convention apig-<org>-<domain>-<suffix>-<env>"
  }

  assert {
    condition     = google_api_gateway_gateway.this.gateway_id == "apig-gw-test-ml-inference-np-sg"
    error_message = "Gateway ID does not follow naming convention apig-gw-<org>-<domain>-<suffix>-<env>-<region_code>"
  }

  assert {
    condition     = google_api_gateway_api_config.this.api_config_id == "apigc-test-ml-inference-np"
    error_message = "Config ID does not follow naming convention apigc-<org>-<domain>-<suffix>-<env>"
  }
}
