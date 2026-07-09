locals {
  swp_name        = "swp-${var.org}-${var.domain}-egress-${var.env}-${var.region_code}"
  policy_name     = "swp-policy-${var.org}-${var.domain}-${var.env}-${var.region_code}"
  proxy_subnet_name = "subnet-${var.org}-${var.domain}-proxy-${var.env}-${var.region_code}"
}

resource "google_compute_subnetwork" "proxy" {
  project       = var.project_id
  region        = var.region
  name          = local.proxy_subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = var.network_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_network_security_gateway_security_policy" "this" {
  provider    = google-beta
  project     = var.project_id
  location    = var.region
  name        = local.policy_name
  description = "Enterprise HTTP/S egress policy for ${var.domain} domain"

  tls_inspection_policy = var.enable_tls_inspection && var.certificate_map_id != "" ? var.certificate_map_id : null
}

resource "google_network_security_gateway_security_policy_rule" "allow" {
  for_each = { for idx, pattern in var.allowed_url_patterns : "allow-${idx}" => pattern }

  provider                = google-beta
  project                 = var.project_id
  location                = var.region
  gateway_security_policy = google_network_security_gateway_security_policy.this.name
  name                    = "allow-${each.key}"
  enabled                 = true
  priority                = 100 + index(var.allowed_url_patterns, each.value)
  session_matcher         = "host() == '${each.value}'"
  basic_profile           = "ALLOW"
}

resource "google_network_security_gateway_security_policy_rule" "deny" {
  for_each = { for idx, pattern in var.denied_url_patterns : "deny-${idx}" => pattern }

  provider                = google-beta
  project                 = var.project_id
  location                = var.region
  gateway_security_policy = google_network_security_gateway_security_policy.this.name
  name                    = "deny-${each.key}"
  enabled                 = true
  priority                = 200 + index(var.denied_url_patterns, each.value)
  session_matcher         = "host() == '${each.value}'"
  basic_profile           = "DENY"
}

resource "google_network_services_gateway" "this" {
  provider               = google-beta
  project                = var.project_id
  location               = var.region
  name                   = local.swp_name
  type                   = "SECURE_WEB_GATEWAY"
  ports                  = [443]
  scope                  = local.swp_name
  network                = var.network_id
  subnetwork             = google_compute_subnetwork.proxy.id
  gateway_security_policy = google_network_security_gateway_security_policy.this.id
  certificate_urls       = var.enable_tls_inspection && var.certificate_map_id != "" ? [var.certificate_map_id] : []
}
