output "cluster_name" {
  description = "The name of the primary Dataproc cluster."
  value       = google_dataproc_cluster.primary.name
}

output "cluster_id" {
  description = "The fully-qualified resource identifier of the primary Dataproc cluster."
  value       = google_dataproc_cluster.primary.id
}

output "dr_cluster_name" {
  description = "The name of the DR standby Dataproc cluster. Empty string when enable_dr_standby is false."
  value       = var.enable_dr_standby ? google_dataproc_cluster.dr[0].name : ""
}
