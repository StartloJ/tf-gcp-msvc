output "secret_name" {
  description = "The fully-qualified resource name of the Secret Manager secret."
  value       = google_secret_manager_secret.this.name
}

output "secret_version_name" {
  description = "The resource name of the initial secret version. Empty string when no initial_value was provided."
  value       = var.initial_value != "" ? google_secret_manager_secret_version.initial[0].name : ""
  sensitive   = true
}
