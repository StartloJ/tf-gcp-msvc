output "inspection_template_id" {
  description = "The resource name of the DLP inspection template."
  value       = google_data_loss_prevention_inspect_template.this.id
}

output "deidentify_template_id" {
  description = "The resource name of the DLP de-identification template. Empty string when deidentify_template_display_name was not provided."
  value       = var.deidentify_template_display_name != "" ? google_data_loss_prevention_deidentify_template.this[0].id : ""
}
