output "endpoint_ip" {
  description = "The IP address of the PSC consumer endpoint."
  value = (
    var.psc_type == "google-apis"
    ? google_compute_global_address.psc_googleapis[0].address
    : google_compute_address.psc_service[0].address
  )
}

output "forwarding_rule_id" {
  description = "The resource ID of the PSC forwarding rule."
  value = (
    var.psc_type == "google-apis"
    ? google_compute_global_forwarding_rule.psc_googleapis[0].id
    : google_compute_forwarding_rule.psc_service[0].id
  )
}

output "dns_zone_name" {
  description = "The name of the private DNS zone created for googleapis.com PSC routing. Empty string when psc_type is service-attachment or create_dns_zone is false."
  value       = (var.psc_type == "google-apis" && var.create_dns_zone) ? google_dns_managed_zone.psc_googleapis[0].name : ""
}
