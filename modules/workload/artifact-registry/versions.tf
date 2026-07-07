// Module artifact-registry v0.3.0

terraform {
  required_version = ">= 1.12"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.10, < 8"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.10, < 8"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/artifact-registry/v0.3.0"
  }
  provider_meta "google-beta" {
    module_name = "blueprints/terraform/artifact-registry/v0.3.0"
  }
}
