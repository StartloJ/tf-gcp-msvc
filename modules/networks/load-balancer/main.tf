locals {
  lb_name   = "lb-${var.org}-${var.domain}-${var.load_balancer_type}-${var.env}-${var.region_code}"
  is_global = var.load_balancer_type == "external-global"
}

resource "google_compute_health_check" "global" {
  count   = local.is_global ? 1 : 0
  project = var.project_id
  name    = "${local.lb_name}-hc"

  http_health_check {
    port         = 80
    request_path = var.health_check_path
  }
}

resource "google_compute_region_health_check" "regional" {
  count   = local.is_global ? 0 : 1
  project = var.project_id
  region  = var.region
  name    = "${local.lb_name}-hc"

  http_health_check {
    port         = 80
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "global" {
  count                 = local.is_global ? 1 : 0
  project               = var.project_id
  name                  = "${local.lb_name}-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.global[0].id]

  dynamic "backend" {
    for_each = var.backend_service_backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
    }
  }
}

resource "google_compute_region_backend_service" "regional" {
  count                 = local.is_global ? 0 : 1
  project               = var.project_id
  region                = var.region
  name                  = "${local.lb_name}-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.regional[0].id]

  dynamic "backend" {
    for_each = var.backend_service_backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
    }
  }
}

resource "google_compute_url_map" "global" {
  count           = local.is_global ? 1 : 0
  project         = var.project_id
  name            = "${local.lb_name}-urlmap"
  default_service = google_compute_backend_service.global[0].id
}

resource "google_compute_region_url_map" "regional" {
  count           = local.is_global ? 0 : 1
  project         = var.project_id
  region          = var.region
  name            = "${local.lb_name}-urlmap"
  default_service = google_compute_region_backend_service.regional[0].id
}

resource "google_compute_managed_ssl_certificate" "this" {
  count   = local.is_global && length(var.ssl_certificate_domains) > 0 ? 1 : 0
  project = var.project_id
  name    = "${local.lb_name}-cert"

  managed {
    domains = var.ssl_certificate_domains
  }
}

resource "google_compute_target_https_proxy" "global" {
  count   = local.is_global ? 1 : 0
  project = var.project_id
  name    = "${local.lb_name}-https-proxy"
  url_map = google_compute_url_map.global[0].id
  ssl_certificates = var.custom_ssl_certificate_id != "" ? [var.custom_ssl_certificate_id] : (
    length(google_compute_managed_ssl_certificate.this) > 0 ? [google_compute_managed_ssl_certificate.this[0].id] : []
  )
}

resource "google_compute_global_forwarding_rule" "global" {
  count                 = local.is_global ? 1 : 0
  project               = var.project_id
  name                  = "${local.lb_name}-fwd"
  target                = google_compute_target_https_proxy.global[0].id
  ip_protocol           = "TCP"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_region_target_https_proxy" "regional" {
  count   = local.is_global ? 0 : 1
  project = var.project_id
  region  = var.region
  name    = "${local.lb_name}-https-proxy"
  url_map = google_compute_region_url_map.regional[0].id
  ssl_certificates = var.custom_ssl_certificate_id != "" ? [var.custom_ssl_certificate_id] : []
}

resource "google_compute_forwarding_rule" "regional" {
  count                 = local.is_global ? 0 : 1
  project               = var.project_id
  region                = var.region
  name                  = "${local.lb_name}-fwd"
  target                = google_compute_region_target_https_proxy.regional[0].id
  network               = var.network_id
  subnetwork            = var.subnet_id
  ip_protocol           = "TCP"
  port_range            = "443"
  load_balancing_scheme = "INTERNAL_MANAGED"
}
