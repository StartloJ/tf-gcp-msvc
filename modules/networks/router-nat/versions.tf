terraform {
  required_version = ">= 1.12"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.10, < 8"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-cloud-nat/v6.0.0"
  }
}
