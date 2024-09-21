terraform {
  required_version = ">= 0.13"
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 4.51, < 7"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-cloud-nat/v5.2.0"
  }

}