mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id    = "test-project"
  repository_id = "test-repo"
  location      = "asia-southeast1"
  format        = "DOCKER"
}

run "plan_docker_repository" {
  command = plan

  assert {
    condition     = var.repository_id == "test-repo"
    error_message = "repository_id variable not passed correctly"
  }

  assert {
    condition     = var.format == "DOCKER"
    error_message = "format variable should be DOCKER"
  }

  assert {
    condition     = var.location == "asia-southeast1"
    error_message = "location variable not passed correctly"
  }
}

run "plan_maven_repository" {
  command = plan

  variables {
    repository_id = "test-maven-repo"
    format        = "MAVEN"
  }

  assert {
    condition     = var.format == "MAVEN"
    error_message = "format variable should be MAVEN"
  }

  assert {
    condition     = var.repository_id == "test-maven-repo"
    error_message = "repository_id should be test-maven-repo"
  }
}
