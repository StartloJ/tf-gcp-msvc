mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id        = "test-prj"
  org               = "test"
  domain            = "ml"
  env               = "np"
  region_code       = "sg"
  log_bucket_suffix = "audit"
  labels            = { managed_by = "terraform" }
}

run "plan_cloud_logging_bucket" {
  command = plan

  assert {
    condition     = google_logging_project_bucket_config.this.bucket_id == "logbkt-test-ml-audit-np-sg"
    error_message = "Log bucket ID does not follow naming convention logbkt-<org>-<domain>-<suffix>-<env>-<region_code>"
  }

  assert {
    condition     = google_logging_project_bucket_config.this.retention_days == 30
    error_message = "Retention days should default to 30"
  }

  assert {
    condition     = google_logging_project_sink.this.name == "logsink-test-ml-audit-np-sg"
    error_message = "Log sink name does not follow naming convention logsink-<org>-<domain>-<suffix>-<env>-<region_code>"
  }
}

run "plan_cloud_logging_with_metrics" {
  command = plan

  variables {
    metric_descriptors = {
      errors = {
        description = "Count of error log entries"
        metric_kind = "DELTA"
        value_type  = "INT64"
        filter      = "severity>=ERROR"
      }
    }
  }

  assert {
    condition     = length(google_logging_metric.metrics) == 1
    error_message = "One log-based metric should be created per entry in metric_descriptors"
  }
}
