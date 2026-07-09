locals {
  dataplex_lake_name = "lake-${var.org}-${var.domain}-${var.lake_name_suffix}-${var.env}"
}

resource "google_dataplex_lake" "this" {
  project  = var.project_id
  location = var.region
  name     = local.dataplex_lake_name
  labels   = var.labels
}

resource "google_dataplex_zone" "zones" {
  for_each = var.zones

  project      = var.project_id
  location     = var.region
  lake         = google_dataplex_lake.this.name
  name         = each.key
  type         = each.value.type
  labels       = var.labels

  resource_spec {
    location_type = "SINGLE_REGION"
  }

  discovery_spec {
    enabled = false
  }
}

resource "google_dataplex_asset" "buckets" {
  for_each = {
    for pair in flatten([
      for zone_name, zone in var.zones : [
        for bucket in zone.asset_buckets : { zone = zone_name, bucket = bucket }
      ]
    ]) : "${pair.zone}/${pair.bucket}" => pair
  }

  project   = var.project_id
  location  = var.region
  lake      = google_dataplex_lake.this.name
  dataplex_zone = google_dataplex_zone.zones[each.value.zone].name
  name      = replace(each.value.bucket, "/[^a-z0-9-]/", "-")
  labels    = var.labels

  resource_spec {
    name = "projects/${var.project_id}/buckets/${each.value.bucket}"
    type = "STORAGE_BUCKET"
  }

  discovery_spec {
    enabled = false
  }
}

resource "google_dataplex_lake_iam_member" "stewards" {
  for_each = toset(var.data_stewards)

  project  = var.project_id
  location = var.region
  lake     = google_dataplex_lake.this.name
  role     = "roles/dataplex.dataOwner"
  member   = each.value
}
