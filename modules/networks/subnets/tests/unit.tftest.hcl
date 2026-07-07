mock_provider "google" {}

variables {
  project_id   = "test-project"
  network_name = "test-network"
  subnets = [
    {
      subnet_name   = "test-subnet-01"
      subnet_ip     = "10.10.0.0/24"
      subnet_region = "asia-southeast1"
    }
  ]
}

run "plan_with_one_subnet" {
  command = plan

  assert {
    condition     = length(var.subnets) == 1
    error_message = "Expected exactly 1 subnet in the variable"
  }

  assert {
    condition     = var.subnets[0].subnet_name == "test-subnet-01"
    error_message = "Subnet name not passed correctly"
  }

  assert {
    condition     = var.subnets[0].subnet_region == "asia-southeast1"
    error_message = "Subnet region not passed correctly"
  }
}

run "plan_with_multiple_subnets" {
  command = plan

  variables {
    subnets = [
      {
        subnet_name   = "snet-app"
        subnet_ip     = "10.10.0.0/24"
        subnet_region = "asia-southeast1"
      },
      {
        subnet_name   = "snet-data"
        subnet_ip     = "10.10.1.0/24"
        subnet_region = "asia-southeast1"
      }
    ]
  }

  assert {
    condition     = length(var.subnets) == 2
    error_message = "Expected 2 subnets"
  }
}

run "plan_shared_vpc_subnet_delegation" {
  command = plan

  variables {
    subnets = [
      {
        subnet_name   = "snet-shared"
        subnet_ip     = "10.10.2.0/24"
        subnet_region = "asia-southeast1"
      }
    ]
    subnet_users = {
      "snet-shared" = [
        "serviceAccount:sa-svc@service-project.iam.gserviceaccount.com",
        "group:devteam@example.com",
      ]
    }
  }

  assert {
    condition     = length(google_compute_subnetwork_iam_member.subnet_users) == 2
    error_message = "Expected 2 IAM member bindings for subnet delegation"
  }
}

run "plan_no_subnet_delegation" {
  command = plan

  variables {
    subnet_users = {}
  }

  assert {
    condition     = length(google_compute_subnetwork_iam_member.subnet_users) == 0
    error_message = "Expected no IAM bindings when subnet_users is empty"
  }
}
