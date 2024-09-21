terraform {
  required_version = ">= 0.13.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.83, < 7"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network:routes/v9.1.0"
  }
}