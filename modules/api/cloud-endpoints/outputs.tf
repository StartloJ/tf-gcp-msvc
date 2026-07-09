output "service_name" {
  description = "The managed service name for the Cloud Endpoints service."
  value       = google_endpoints_service.this.service_name
}

output "config_id" {
  description = "The configuration ID of the deployed Cloud Endpoints service."
  value       = google_endpoints_service.this.config_id
}
