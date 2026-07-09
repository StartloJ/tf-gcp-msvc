mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id       = "test-prj"
  org              = "test"
  domain           = "ml"
  env              = "np"
  region_code      = "sg"
  lake_name_suffix = "raw"
  zones = {
    raw-ingest = {
      type          = "RAW"
      asset_buckets = ["test-bucket"]
    }
  }
  labels = { managed_by = "terraform" }
}

run "plan_dataplex_lake" {
  command = plan

  assert {
    condition     = google_dataplex_lake.this.name == "lake-test-ml-raw-np"
    error_message = "Dataplex lake name does not follow naming convention lake-<org>-<domain>-<suffix>-<env>"
  }

  assert {
    condition     = google_dataplex_lake.this.labels["managed_by"] == "terraform"
    error_message = "Labels not applied to Dataplex lake"
  }

  assert {
    condition     = google_dataplex_zone.zones["raw-ingest"].type == "RAW"
    error_message = "Dataplex zone type should be RAW"
  }

  assert {
    condition     = length(google_dataplex_asset.buckets) == 1
    error_message = "One asset should be created for each bucket in the zone"
  }
}

run "plan_dataplex_with_stewards" {
  command = plan

  variables {
    data_stewards = ["user:steward@example.com"]
  }

  assert {
    condition     = length(google_dataplex_lake_iam_member.stewards) == 1
    error_message = "IAM steward binding should be created for each data_steward"
  }
}
