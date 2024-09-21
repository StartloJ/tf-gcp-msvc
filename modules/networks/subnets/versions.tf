terraform {
  required_version = ">= 0.13.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.25.0, < 7"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network:subnets/v9.1.0"
  }
}