mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id  = "test-prj"
  org         = "test"
  domain      = "ml"
  env         = "np"
  region_code = "sg"
  secret_id   = "my-api-key"
  labels      = { managed_by = "terraform" }
}

run "plan_secret_automatic_replication" {
  command = plan

  assert {
    condition     = google_secret_manager_secret.this.secret_id == "my-api-key"
    error_message = "Secret ID not set correctly"
  }

  assert {
    condition     = google_secret_manager_secret.this.replication[0].auto != null
    error_message = "Automatic replication should be configured by default"
  }

  assert {
    condition     = google_secret_manager_secret.this.labels["managed_by"] == "terraform"
    error_message = "Labels not applied to secret"
  }

  assert {
    condition     = length(google_secret_manager_secret_version.initial) == 0
    error_message = "No initial version should be created when initial_value is empty"
  }
}

run "plan_secret_with_initial_value" {
  command = plan

  variables {
    initial_value    = "super-secret-value"
    accessor_members = ["serviceAccount:app@test-prj.iam.gserviceaccount.com"]
  }

  assert {
    condition     = length(google_secret_manager_secret_version.initial) == 1
    error_message = "Initial version should be created when initial_value is set"
  }

  assert {
    condition     = length(google_secret_manager_secret_iam_member.accessor) == 1
    error_message = "IAM accessor binding should be created for each accessor_member"
  }
}
