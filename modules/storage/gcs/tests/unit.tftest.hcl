mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id         = "test-prj"
  org                = "test"
  domain             = "ml"
  env                = "np"
  region_code        = "sg"
  bucket_name_suffix = "models"
  unique_suffix      = "a1b2"
  labels             = { managed_by = "terraform" }
}

run "plan_standard_bucket" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.name == "bkt-test-ml-models-np-sg-a1b2"
    error_message = "Bucket name does not follow naming convention bkt-<org>-<domain>-<suffix>-<env>-<region_code>-<unique_suffix>"
  }

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access should be enabled by default"
  }

  assert {
    condition     = google_storage_bucket.this.labels["managed_by"] == "terraform"
    error_message = "Labels not applied to primary GCS bucket"
  }

  assert {
    condition     = length(google_storage_bucket.dr) == 0
    error_message = "DR bucket should not be created when dr_replication_region is empty"
  }
}

run "plan_dr_bucket" {
  command = plan

  variables {
    dr_replication_region = "asia-east1"
  }

  assert {
    condition     = length(google_storage_bucket.dr) == 1
    error_message = "DR bucket should be created when dr_replication_region is set"
  }

  assert {
    condition     = google_storage_bucket.dr[0].location == "asia-east1"
    error_message = "DR bucket should be in the specified dr_replication_region"
  }
}
