/********************************************
    example Card GCP CICD
*********************************************/

module "example_gar_api" {
  source = "../../modules/workload/artifact-registry"

  project_id    = data.google_project.example.project_id
  location      = local.default_region
  repository_id = "example-api"
  format        = "DOCKER"
  description   = "Artifact Registry for example API"

  cleanup_policies = {
    cleanup_delete_30d = {
      action = "DELETE"
      condition = {
        tag_state = "ANY"
        tag_prefixes = [
          "dev",
        ]
        older_than = "2592000s" // 30 days
      }
    }
    cleanup_keep_minimum_3v = {
      action = "KEEP"
      most_recent_versions = {
        package_name_prefixes = [
          "example-api",
        ]
        keep_count = 3
      }
    }
  }

  # members = {
  #   readers = [
  #     "serviceAccount:${module.example-gke-private.service_account}",
  #   ]
  # }

  labels = {
    app = "example-api"
    env = "dev"
  }

}

module "example_gar_cms" {
  source = "../../modules/workload/artifact-registry"

  project_id    = data.google_project.example.project_id
  location      = local.default_region
  repository_id = "example-cms"
  format        = "DOCKER"
  description   = "Artifact Registry for example CMS"

  cleanup_policies = {
    cleanup_delete_30d = {
      action = "DELETE"
      condition = {
        tag_state = "ANY"
        tag_prefixes = [
          "dev",
        ]
        older_than = "2592000s" // 30 days
      }
    }
    cleanup_keep_minimum_3v = {
      action = "KEEP"
      most_recent_versions = {
        package_name_prefixes = [
          "example-cms",
        ]
        keep_count = 3
      }
    }
  }
  # members = {
  #   readers = [
  #     "serviceAccount:${module.example-gke-private.service_account}",
  #   ]
  # }

  labels = {
    app = "example-cms"
    env = "dev"
  }

}