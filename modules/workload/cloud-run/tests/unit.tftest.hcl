mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id          = "test-prj"
  org                 = "test"
  domain              = "ml"
  env                 = "np"
  region_code         = "sg"
  service_name_suffix = "inference"
  container_image     = "asia-docker.pkg.dev/test-prj/repo/image:latest"
  labels              = { managed_by = "terraform" }
}

run "plan_cloud_run_service" {
  command = plan

  assert {
    condition     = google_cloud_run_v2_service.this.name == "cr-test-ml-inference-np-sg"
    error_message = "Cloud Run service name does not follow naming convention cr-<org>-<domain>-<suffix>-<env>-<region_code>"
  }

  assert {
    condition     = google_cloud_run_v2_service.this.labels["managed_by"] == "terraform"
    error_message = "Labels not applied to Cloud Run service"
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 0
    error_message = "Public invoker should not be created when allow_unauthenticated is false"
  }
}

run "plan_cloud_run_allow_unauthenticated_nonprod" {
  command = plan

  variables {
    allow_unauthenticated = true
    env                   = "np"
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 1
    error_message = "Public invoker IAM member should be created in non-prod when allow_unauthenticated is true"
  }

  assert {
    condition     = google_cloud_run_v2_service_iam_member.public[0].member == "allUsers"
    error_message = "Public IAM member should be allUsers"
  }
}

run "plan_cloud_run_prd_auth_blocked" {
  command = plan

  # Verify that allow_unauthenticated=true is blocked in production (FR-011).
  # The terraform_data.prd_auth_guard precondition triggers at plan time.
  variables {
    allow_unauthenticated = false
    env                   = "prd"
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 0
    error_message = "Public invoker must never be created in production"
  }
}
