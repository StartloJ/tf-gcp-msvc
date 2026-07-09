locals {
  kms_key_ring_name = "kr-${var.org}-${var.domain}-${var.key_ring_suffix}-${var.env}-${var.region_code}"
}

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = local.kms_key_ring_name
  location = var.region

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "keys" {
  for_each = var.keys

  name            = each.key
  key_ring        = google_kms_key_ring.this.id
  rotation_period = each.value.rotation_period
  purpose         = each.value.purpose

  version_template {
    algorithm = each.value.algorithm
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "binding" {
  for_each = {
    for pair in flatten([
      for key, members in var.key_iam_bindings : [
        for m in members : { key = key, member = m }
      ]
    ]) : "${pair.key}/${pair.member}" => pair
  }

  crypto_key_id = google_kms_crypto_key.keys[each.value.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value.member
}
