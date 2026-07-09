mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id   = "test-prj"
  org          = "test"
  domain       = "ml"
  env          = "np"
  region_code  = "sg"
  service_name = "my-api.endpoints.test-prj.cloud.goog"
  openapi_spec = "swagger: \"2.0\"\ninfo:\n  title: Test\n  version: \"1.0\"\nhost: my-api.endpoints.test-prj.cloud.goog\npaths: {}"
  labels       = { managed_by = "terraform" }
}

run "plan_cloud_endpoints" {
  command = plan

  assert {
    condition     = google_endpoints_service.this.service_name == "my-api.endpoints.test-prj.cloud.goog"
    error_message = "Cloud Endpoints service name not set correctly"
  }

  assert {
    condition     = length(google_project_iam_member.consumer) == 0
    error_message = "No IAM consumer bindings should be created when iam_consumers is empty"
  }
}

run "plan_cloud_endpoints_with_consumers" {
  command = plan

  variables {
    iam_consumers = ["serviceAccount:app@test-prj.iam.gserviceaccount.com"]
  }

  assert {
    condition     = length(google_project_iam_member.consumer) == 1
    error_message = "IAM consumer binding should be created for each iam_consumer"
  }
}
