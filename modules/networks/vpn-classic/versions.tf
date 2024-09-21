terraform {
  required_version = ">=0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-vpn/v4.0.1"
  }
}