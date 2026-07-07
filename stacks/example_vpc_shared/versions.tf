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

  # Uncomment and configure when deploying to real GCP
  # backend "gcs" {
  #   bucket = "your-tf-state-bucket"
  #   prefix = "shared-vpc"
  # }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network/v9.4.0"
  }
}
