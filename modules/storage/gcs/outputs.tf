output "bucket_name" {
  description = "The name of the primary Cloud Storage bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "The gs:// URI of the primary Cloud Storage bucket."
  value       = google_storage_bucket.this.url
}

output "dr_bucket_name" {
  description = "The name of the DR replica bucket. Empty string when dr_replication_region is not set."
  value       = var.dr_replication_region != "" ? google_storage_bucket.dr[0].name : ""
}
