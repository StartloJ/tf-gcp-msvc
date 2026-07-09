locals {
  gcs_bucket_name    = "bkt-${var.org}-${var.domain}-${var.bucket_name_suffix}-${var.env}-${var.region_code}-${var.unique_suffix}"
  dr_gcs_bucket_name = "bkt-${var.org}-${var.domain}-${var.bucket_name_suffix}-${var.env}-dr-${var.unique_suffix}"
}

resource "google_storage_bucket" "this" {
  project                     = var.project_id
  name                        = local.gcs_bucket_name
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  labels                      = var.labels

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type = lifecycle_rule.value.action
      }
      condition {
        age = lifecycle_rule.value.age_days
      }
    }
  }
}

resource "google_storage_bucket" "dr" {
  count = var.dr_replication_region != "" ? 1 : 0

  project                     = var.project_id
  name                        = local.dr_gcs_bucket_name
  location                    = var.dr_replication_region
  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  labels                      = var.labels

  versioning {
    enabled = var.versioning_enabled
  }
}

# DR replication is managed via Cloud Storage Transfer Service or Object Lifecycle.
# The DR bucket above is created in var.dr_replication_region as the replication target.
# Automated replication jobs should be configured at the platform level or
# via google_storage_transfer_job (not included here to keep the module stateless).
