output "dataset_id" {
  description = "The BigQuery dataset ID. Use this to reference the dataset from other modules or stacks."
  value       = google_bigquery_dataset.this.dataset_id
}

output "dataset_self_link" {
  description = "The URI of the created BigQuery dataset resource."
  value       = google_bigquery_dataset.this.self_link
}
