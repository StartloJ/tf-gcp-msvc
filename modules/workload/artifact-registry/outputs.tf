output "artifact_id" {
  description = "an identifier for the resource"
  value       = google_artifact_registry_repository.repo.id
}

output "artifact_name" {
  description = "an identifier for the resource"
  value       = google_artifact_registry_repository.repo.name
}

output "create_time" {
  description = "The time when the repository was created."
  value       = google_artifact_registry_repository.repo.create_time
}

output "update_time" {
  description = "The time when the repository was last updated."
  value       = google_artifact_registry_repository.repo.update_time
}