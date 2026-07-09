output "forwarding_rule_ip" {
  description = "The IP address of the load balancer forwarding rule."
  value = (
    var.load_balancer_type == "external-global"
    ? google_compute_global_forwarding_rule.global[0].ip_address
    : google_compute_forwarding_rule.regional[0].ip_address
  )
}

output "backend_service_id" {
  description = "The resource ID of the backend service (global for external-global, regional for internal-regional)."
  value = (
    var.load_balancer_type == "external-global"
    ? google_compute_backend_service.global[0].id
    : google_compute_region_backend_service.regional[0].id
  )
}

output "url_map_id" {
  description = "The resource ID of the URL map."
  value = (
    var.load_balancer_type == "external-global"
    ? google_compute_url_map.global[0].id
    : google_compute_region_url_map.regional[0].id
  )
}
