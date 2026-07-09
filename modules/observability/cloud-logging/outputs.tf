output "log_bucket_id" {
  description = "The resource ID of the Cloud Logging log bucket."
  value       = google_logging_project_bucket_config.this.id
}

output "sink_name" {
  description = "The name of the log sink routing entries to the log bucket."
  value       = google_logging_project_sink.this.name
}

output "sink_writer_identity" {
  description = "The service account identity of the log sink writer. Grant this identity write access to the destination if needed."
  value       = google_logging_project_sink.this.writer_identity
}
