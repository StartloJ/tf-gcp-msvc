terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.33, < 7"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-network:firewall-rules/v9.1.0"
  }
}