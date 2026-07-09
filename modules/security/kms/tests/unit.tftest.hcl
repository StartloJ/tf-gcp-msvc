mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id      = "test-prj"
  org             = "test"
  domain          = "ml"
  env             = "np"
  region_code     = "sg"
  key_ring_suffix = "data"
  keys = {
    cmek = {
      rotation_period = "2592000s"
      algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
      purpose         = "ENCRYPT_DECRYPT"
    }
  }
  labels = { managed_by = "terraform" }
}

run "plan_kms_key_ring" {
  command = plan

  assert {
    condition     = google_kms_key_ring.this.name == "kr-test-ml-data-np-sg"
    error_message = "Key ring name does not follow naming convention kr-<org>-<domain>-<suffix>-<env>-<region_code>"
  }

  assert {
    condition     = google_kms_crypto_key.keys["cmek"].rotation_period == "2592000s"
    error_message = "Crypto key rotation period not set correctly"
  }

  assert {
    condition     = google_kms_crypto_key.keys["cmek"].purpose == "ENCRYPT_DECRYPT"
    error_message = "Crypto key purpose not set correctly"
  }
}

run "plan_kms_with_iam_binding" {
  command = plan

  variables {
    key_iam_bindings = {
      cmek = ["serviceAccount:app@test-prj.iam.gserviceaccount.com"]
    }
  }

  assert {
    condition     = length(google_kms_crypto_key_iam_member.binding) == 1
    error_message = "KMS IAM binding should be created for each key/member pair"
  }
}
