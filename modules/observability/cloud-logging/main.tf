locals {
  log_bucket_id = "logbkt-${var.org}-${var.domain}-${var.log_bucket_suffix}-${var.env}-${var.region_code}"
  sink_name     = "logsink-${var.org}-${var.domain}-${var.log_bucket_suffix}-${var.env}-${var.region_code}"
}

resource "google_logging_project_bucket_config" "this" {
  project          = var.project_id
  location         = var.region
  bucket_id        = local.log_bucket_id
  retention_days   = var.retention_days
  enable_analytics = var.enable_analytics
}

resource "google_logging_project_sink" "this" {
  project = var.project_id
  name    = local.sink_name

  destination = "logging.googleapis.com/${google_logging_project_bucket_config.this.id}"
  filter      = var.log_sink_filter != "" ? var.log_sink_filter : null

  unique_writer_identity = true
}

resource "google_logging_metric" "metrics" {
  for_each = var.metric_descriptors

  project     = var.project_id
  name        = "${var.domain}-${each.key}-${var.env}"
  description = each.value.description
  filter      = each.value.filter

  metric_descriptor {
    metric_kind = each.value.metric_kind
    value_type  = each.value.value_type
  }
}
