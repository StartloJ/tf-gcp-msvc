locals {
  service_name = "cr-${var.org}-${var.domain}-${var.service_name_suffix}-${var.env}-${var.region_code}"

  ingress_map = {
    "all"                              = "INGRESS_TRAFFIC_ALL"
    "internal"                         = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    "internal-and-cloud-load-balancing" = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
}

# SECURITY: allow_unauthenticated = true is blocked in production environments (FR-011).
# This check runs at plan time and fails before any resource is created.
resource "terraform_data" "prd_auth_guard" {
  count = var.env == "prd" && var.allow_unauthenticated ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(var.env == "prd" && var.allow_unauthenticated)
      error_message = "allow_unauthenticated = true is prohibited when env == \"prd\". Cloud Run services in production must require authentication."
    }
  }
}

resource "google_cloud_run_v2_service" "this" {
  project  = var.project_id
  location = var.region
  name     = local.service_name
  labels   = var.labels

  ingress = local.ingress_map[var.ingress_setting]

  template {
    service_account = var.service_account_email != "" ? var.service_account_email : null

    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != "" ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = "ALL_TRAFFIC"
      }
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.container_image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  count = var.allow_unauthenticated && var.env != "prd" ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
