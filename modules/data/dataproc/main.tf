locals {
  dataproc_name = "dpc-${var.org}-${var.domain}-${var.cluster_name_suffix}-${var.env}-${var.region_code}-01"
}

resource "google_dataproc_cluster" "primary" {
  name    = local.dataproc_name
  project = var.project_id
  region  = var.region
  labels  = var.labels

  cluster_config {
    master_config {
      machine_type  = var.master_machine_type
      num_instances = 1

      disk_config {
        boot_disk_size_gb = var.master_disk_gb
      }
    }

    worker_config {
      machine_type  = var.worker_machine_type
      num_instances = var.worker_count

      disk_config {
        boot_disk_size_gb = var.worker_disk_gb
      }
    }

    gce_cluster_config {
      subnetwork      = var.subnet_name
      service_account = var.service_account != "" ? var.service_account : null
    }

    dynamic "initialization_action" {
      for_each = var.initialization_actions
      content {
        script      = initialization_action.value
        timeout_sec = 300
      }
    }
  }
}

resource "google_dataproc_cluster" "dr" {
  count = var.enable_dr_standby ? 1 : 0

  name    = "${local.dataproc_name}-dr"
  project = var.project_id
  region  = var.dr_region
  labels  = var.labels

  cluster_config {
    master_config {
      machine_type  = var.master_machine_type
      num_instances = 1

      disk_config {
        boot_disk_size_gb = var.master_disk_gb
      }
    }

    worker_config {
      machine_type  = var.worker_machine_type
      num_instances = var.worker_count

      disk_config {
        boot_disk_size_gb = var.worker_disk_gb
      }
    }

    gce_cluster_config {
      subnetwork      = var.subnet_name
      service_account = var.service_account != "" ? var.service_account : null
    }

    dynamic "initialization_action" {
      for_each = var.initialization_actions
      content {
        script      = initialization_action.value
        timeout_sec = 300
      }
    }
  }
}
