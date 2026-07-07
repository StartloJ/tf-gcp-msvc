mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "random" {}
mock_provider "null" {}

variables {
  project_id                  = "test-project"
  name                        = "test-pg-instance"
  database_version            = "POSTGRES_15"
  region                      = "asia-southeast1"
  zone                        = "asia-southeast1-a"
  tier                        = "db-f1-micro"
  enable_default_user         = false
  deletion_protection         = false
  deletion_protection_enabled = false
}

run "plan_postgresql_instance" {
  command = plan

  assert {
    condition     = var.project_id == "test-project"
    error_message = "project_id variable not passed correctly"
  }

  assert {
    condition     = var.database_version == "POSTGRES_15"
    error_message = "database_version variable not passed correctly"
  }

  assert {
    condition     = var.name == "test-pg-instance"
    error_message = "name variable not passed correctly"
  }
}

run "plan_postgresql_with_random_name" {
  command = plan

  variables {
    random_instance_name = true
  }

  assert {
    condition     = var.random_instance_name == true
    error_message = "random_instance_name should be true"
  }

  assert {
    condition     = var.zone == "asia-southeast1-a"
    error_message = "zone should be set to bypass data source lookup"
  }
}
