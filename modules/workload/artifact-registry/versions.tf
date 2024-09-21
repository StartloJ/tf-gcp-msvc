// Module artifact-registry v0.2.0

terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.26.0, < 7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.26.0, < 7"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/artifact-registry/v0.2.0"
  }
}