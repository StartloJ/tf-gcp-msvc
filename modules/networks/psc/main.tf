locals {
  psc_address_name = "psc-${var.org}-${var.domain}-${var.psc_type == "google-apis" ? "googleapis" : "svc"}-${var.env}-${var.region_code}"
  psc_fwd_rule_name = "psc-${var.org}-${var.domain}-${var.psc_type == "google-apis" ? "googleapis" : "svc"}-${var.env}-${var.region_code}-fwd"
}

resource "google_compute_global_address" "psc_googleapis" {
  count        = var.psc_type == "google-apis" ? 1 : 0
  project      = var.project_id
  name         = local.psc_address_name
  purpose      = "PRIVATE_SERVICE_CONNECT"
  address_type = "INTERNAL"
  network      = var.network_id
}

resource "google_compute_global_forwarding_rule" "psc_googleapis" {
  count                 = var.psc_type == "google-apis" ? 1 : 0
  project               = var.project_id
  name                  = local.psc_fwd_rule_name
  target                = "all-apis"
  network               = var.network_id
  ip_address            = google_compute_global_address.psc_googleapis[0].id
  load_balancing_scheme = ""
  no_automate_dns_zone  = !var.create_dns_zone
}

resource "google_dns_managed_zone" "psc_googleapis" {
  count       = var.psc_type == "google-apis" && var.create_dns_zone ? 1 : 0
  project     = var.project_id
  name        = "psc-${var.org}-${var.domain}-googleapis-${var.env}"
  dns_name    = "googleapis.com."
  description = "Private DNS zone for PSC googleapis.com endpoint"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_id
    }
  }
}

resource "google_dns_record_set" "psc_googleapis_wildcard" {
  count        = var.psc_type == "google-apis" && var.create_dns_zone ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.psc_googleapis[0].name
  name         = "*.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.psc_googleapis[0].address]
}

resource "google_compute_address" "psc_service" {
  count        = var.psc_type == "service-attachment" ? 1 : 0
  project      = var.project_id
  region       = var.region
  name         = local.psc_address_name
  purpose      = "GCE_ENDPOINT"
  address_type = "INTERNAL"
  subnetwork   = var.subnet_id
}

resource "google_compute_forwarding_rule" "psc_service" {
  count                 = var.psc_type == "service-attachment" ? 1 : 0
  project               = var.project_id
  region                = var.region
  name                  = local.psc_fwd_rule_name
  target                = var.service_attachment_uri
  network               = var.network_id
  subnetwork            = var.subnet_id
  ip_address            = google_compute_address.psc_service[0].id
  load_balancing_scheme = ""
}
