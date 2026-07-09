output "key_ring_id" {
  description = "The fully-qualified resource ID of the KMS key ring."
  value       = google_kms_key_ring.this.id
}

output "key_ids" {
  description = "Map of crypto key name to fully-qualified key resource ID. Use these IDs to configure CMEK on other GCP resources."
  value       = { for k, key in google_kms_crypto_key.keys : k => key.id }
}
