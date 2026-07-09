locals {
  dlp_template_name = "dlpt-${var.org}-${var.domain}-${var.env}-pii-${var.region_code}"
}

resource "google_data_loss_prevention_inspect_template" "this" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  display_name = var.inspection_template_display_name
  template_id  = local.dlp_template_name

  inspect_config {
    dynamic "info_types" {
      for_each = var.info_types
      content {
        name = info_types.value
      }
    }
  }
}

resource "google_data_loss_prevention_deidentify_template" "this" {
  count = var.deidentify_template_display_name != "" ? 1 : 0

  parent       = "projects/${var.project_id}/locations/${var.region}"
  display_name = var.deidentify_template_display_name

  deidentify_config {
    info_type_transformations {
      transformations {
        primitive_transformation {
          replace_with_info_type_config = true
        }
      }
    }
  }
}
