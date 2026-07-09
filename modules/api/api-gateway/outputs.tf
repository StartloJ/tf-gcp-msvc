output "gateway_id" {
  description = "The resource ID of the API Gateway gateway."
  value       = google_api_gateway_gateway.this.id
}

output "default_hostname" {
  description = "The default hostname assigned to the API Gateway gateway."
  value       = google_api_gateway_gateway.this.default_hostname
}

output "api_id" {
  description = "The resource ID of the API Gateway API resource."
  value       = google_api_gateway_api.this.id
}
