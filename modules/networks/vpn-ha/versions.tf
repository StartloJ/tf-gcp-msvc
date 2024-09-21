terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.64, < 7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.64, < 7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-vpn/v4.0.1"
  }
  provider_meta "google-beta" {
    module_name = "blueprints/terraform/terraform-google-vpn/v4.0.1"
  }
}