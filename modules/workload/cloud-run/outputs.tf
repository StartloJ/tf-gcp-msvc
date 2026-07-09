output "service_name" {
  description = "The name of the Cloud Run v2 service."
  value       = google_cloud_run_v2_service.this.name
}

output "service_url" {
  description = "The HTTPS URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.this.uri
}

output "service_id" {
  description = "The fully-qualified resource ID of the Cloud Run service."
  value       = google_cloud_run_v2_service.this.id
}
