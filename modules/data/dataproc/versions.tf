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
}
