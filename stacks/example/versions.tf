terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.64, < 7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }

  backend "gcs" {
    bucket = "example-tf-state"
    prefix = "dev"
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network/v9.1.0"
  }
}