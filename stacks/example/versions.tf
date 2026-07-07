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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6"
    }
  }

  backend "gcs" {
    bucket = "example-tf-state"
    prefix = "dev"
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network/v9.4.0"
  }
}
