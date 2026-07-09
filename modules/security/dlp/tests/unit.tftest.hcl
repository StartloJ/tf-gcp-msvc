mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id                       = "test-prj"
  org                              = "test"
  domain                           = "ml"
  env                              = "np"
  region_code                      = "sg"
  inspection_template_display_name = "PII Scanner"
  info_types                       = ["EMAIL_ADDRESS", "CREDIT_CARD_NUMBER"]
  labels                           = { managed_by = "terraform" }
}

run "plan_dlp_inspection_template" {
  command = plan

  assert {
    condition     = google_data_loss_prevention_inspect_template.this.template_id == "dlpt-test-ml-np-pii-sg"
    error_message = "DLP template ID does not follow naming convention dlpt-<org>-<domain>-<env>-pii-<region_code>"
  }

  assert {
    condition     = google_data_loss_prevention_inspect_template.this.display_name == "PII Scanner"
    error_message = "Inspection template display name not set correctly"
  }

  assert {
    condition     = length(google_data_loss_prevention_deidentify_template.this) == 0
    error_message = "De-identification template should not be created when display name is empty"
  }
}

run "plan_dlp_with_deidentify" {
  command = plan

  variables {
    deidentify_template_display_name = "PII Masker"
  }

  assert {
    condition     = length(google_data_loss_prevention_deidentify_template.this) == 1
    error_message = "De-identification template should be created when display name is provided"
  }
}
