locals {
  bq_dataset_id = "ds_${var.domain}_${var.dataset_id_suffix}_${var.env}_${var.region_code}"
}

resource "google_bigquery_dataset" "this" {
  project    = var.project_id
  dataset_id = local.bq_dataset_id
  location   = var.region
  labels     = var.labels

  default_table_expiration_ms = var.active_table_expiration_ms == 0 ? null : var.active_table_expiration_ms
  delete_contents_on_destroy  = var.delete_contents_on_destroy
}

resource "google_bigquery_dataset_iam_member" "access" {
  for_each = {
    for binding in flatten([
      for b in var.access_bindings : [
        for m in b.members : { role = b.role, member = m }
      ]
    ]) : "${binding.role}/${binding.member}" => binding
  }

  project    = var.project_id
  dataset_id = google_bigquery_dataset.this.dataset_id
  role       = each.value.role
  member     = each.value.member
}
