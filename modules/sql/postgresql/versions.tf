// Module postgresql v23.0.0

terraform {
  required_version = ">= 1.12"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
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
    module_name = "blueprints/terraform/terraform-google-sql-db:postgresql/v23.0.0"
  }
  provider_meta "google-beta" {
    module_name = "blueprints/terraform/terraform-google-sql-db:postgresql/v23.0.0"
  }
}
