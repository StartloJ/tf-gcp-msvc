locals {
  api_id     = "apig-${var.org}-${var.domain}-${var.api_id_suffix}-${var.env}"
  config_id  = "apigc-${var.org}-${var.domain}-${var.gateway_config_id_suffix}-${var.env}"
  gateway_id = "apig-gw-${var.org}-${var.domain}-${var.api_id_suffix}-${var.env}-${var.region_code}"
}

resource "google_api_gateway_api" "this" {
  provider = google-beta
  project  = var.project_id
  api_id   = local.api_id
}

resource "google_api_gateway_api_config" "this" {
  provider      = google-beta
  project       = var.project_id
  api           = google_api_gateway_api.this.api_id
  api_config_id = local.config_id

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = base64encode(var.openapi_spec)
    }
  }

  dynamic "gateway_config" {
    for_each = var.service_account_email != "" ? [1] : []
    content {
      backend_config {
        google_service_account = var.service_account_email
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "this" {
  provider   = google-beta
  project    = var.project_id
  region     = var.region
  api_config = google_api_gateway_api_config.this.id
  gateway_id = local.gateway_id
}
