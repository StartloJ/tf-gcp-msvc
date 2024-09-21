terraform {
  required_version = ">= 0.13.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.64, < 7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.64, < 7"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network:vpc/v9.1.0"
  }
  provider_meta "google-beta" {
    module_name = "blueprints/terraform/terraform-google-network:vpc/v9.1.0"
  }
}