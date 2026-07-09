output "gateway_id" {
  description = "The resource ID of the Secure Web Proxy gateway."
  value       = google_network_services_gateway.this.id
}

output "policy_id" {
  description = "The resource ID of the gateway security policy."
  value       = google_network_security_gateway_security_policy.this.id
}

output "proxy_subnet_id" {
  description = "The resource ID of the proxy-only subnet created for the Secure Web Proxy."
  value       = google_compute_subnetwork.proxy.id
}
