resource "google_secret_manager_secret" "this" {
  project   = var.project_id
  secret_id = var.secret_id
  labels    = var.labels

  dynamic "replication" {
    for_each = var.replication_policy == "automatic" ? [1] : []
    content {
      auto {}
    }
  }

  dynamic "replication" {
    for_each = var.replication_policy == "user-managed" ? [1] : []
    content {
      user_managed {
        dynamic "replicas" {
          for_each = var.replication_regions
          content {
            location = replicas.value
          }
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "initial" {
  count = var.initial_value != "" ? 1 : 0

  secret      = google_secret_manager_secret.this.id
  secret_data = var.initial_value

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = toset(var.accessor_members)

  project   = var.project_id
  secret_id = google_secret_manager_secret.this.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}
