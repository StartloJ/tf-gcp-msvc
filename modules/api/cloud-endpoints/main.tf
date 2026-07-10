resource "google_endpoints_service" "this" {
  project        = var.project_id
  service_name   = var.service_name
  openapi_config = var.openapi_spec
}

resource "google_project_iam_member" "consumer" {
  for_each = toset(var.iam_consumers)

  project = var.project_id
  role    = "roles/servicemanagement.serviceConsumer"
  member  = each.value
}
