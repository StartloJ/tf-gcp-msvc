mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id        = "test-prj"
  org               = "test"
  domain            = "ml"
  env               = "np"
  region_code       = "sg"
  dataset_id_suffix = "features"
  labels            = { managed_by = "terraform" }
}

run "plan_bigquery_dataset" {
  command = plan

  assert {
    condition     = google_bigquery_dataset.this.dataset_id == "ds_ml_features_np_sg"
    error_message = "Dataset ID does not follow naming convention ds_<domain>_<suffix>_<env>_<region_code>"
  }

  assert {
    condition     = google_bigquery_dataset.this.labels["managed_by"] == "terraform"
    error_message = "Labels not applied to BigQuery dataset"
  }

  assert {
    condition     = google_bigquery_dataset.this.default_table_expiration_ms == null
    error_message = "Default table expiration should be null when active_table_expiration_ms is 0"
  }
}

run "plan_bigquery_with_expiration" {
  command = plan

  variables {
    active_table_expiration_ms = 2592000000
  }

  assert {
    condition     = google_bigquery_dataset.this.default_table_expiration_ms == 2592000000
    error_message = "Default table expiration should be set to 2592000000 ms (30 days)"
  }
}
