mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id          = "test-prj"
  org                 = "test"
  domain              = "ml"
  env                 = "np"
  region_code         = "sg"
  cluster_name_suffix = "etl"
  subnet_name         = "test-subnet"
  labels              = { managed_by = "terraform" }
}

run "plan_dataproc_cluster" {
  command = plan

  assert {
    condition     = google_dataproc_cluster.primary.name == "dpc-test-ml-etl-np-sg-01"
    error_message = "Primary cluster name does not follow naming convention dpc-<org>-<domain>-<suffix>-<env>-<region_code>-01"
  }

  assert {
    condition     = google_dataproc_cluster.primary.cluster_config[0].master_config[0].machine_type == "n2-standard-4"
    error_message = "Master machine type should default to n2-standard-4"
  }

  assert {
    condition     = google_dataproc_cluster.primary.cluster_config[0].worker_config[0].machine_type == "n2-standard-8"
    error_message = "Worker machine type should default to n2-standard-8"
  }

  assert {
    condition     = google_dataproc_cluster.primary.labels["managed_by"] == "terraform"
    error_message = "Labels not applied to primary Dataproc cluster"
  }

  assert {
    condition     = length(google_dataproc_cluster.dr) == 0
    error_message = "DR standby cluster should not be created when enable_dr_standby is false"
  }
}

run "plan_dataproc_dr_standby" {
  command = plan

  variables {
    enable_dr_standby = true
    dr_region         = "asia-east1"
  }

  assert {
    condition     = length(google_dataproc_cluster.dr) == 1
    error_message = "DR standby cluster should be created when enable_dr_standby is true"
  }

  assert {
    condition     = google_dataproc_cluster.dr[0].name == "dpc-test-ml-etl-np-sg-01-dr"
    error_message = "DR cluster name should be primary name with -dr suffix"
  }

  assert {
    condition     = google_dataproc_cluster.dr[0].region == "asia-east1"
    error_message = "DR cluster should be deployed in dr_region"
  }
}
