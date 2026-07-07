mock_provider "google" {}
mock_provider "google-beta" {}

# Baseline: host project only, no folder IAM, no service projects
run "plan_host_only_no_folder" {
  command = plan

  variables {
    host_project_id       = "my-host-project"
    host_folder_id        = null
    network_admin_members = []
    service_project_ids   = []
    subnet_users          = {}
  }

  assert {
    condition     = module.shared_vpc.network_name == "shared-vpc"
    error_message = "Shared VPC network name should be shared-vpc"
  }

  assert {
    condition     = length(google_folder_iam_member.xpn_admin) == 0
    error_message = "No folder IAM bindings when host_folder_id is null"
  }

  assert {
    condition     = length(module.shared_vpc.service_project_ids) == 0
    error_message = "No service projects should be attached when list is empty"
  }
}

# Folder IAM only — no service projects yet
run "plan_folder_iam_only" {
  command = plan

  variables {
    host_project_id = "my-host-project"
    host_folder_id  = "123456789012"
    network_admin_members = [
      "group:network-admins@example.com",
      "serviceAccount:terraform@my-host-project.iam.gserviceaccount.com",
    ]
    service_project_ids = []
    subnet_users        = {}
  }

  assert {
    condition     = length(google_folder_iam_member.xpn_admin) == 2
    error_message = "Expected 2 folder-level xpnAdmin IAM bindings"
  }
}

# Full Shared VPC: folder IAM + two service projects + subnet delegation
run "plan_shared_vpc_full" {
  command = plan

  variables {
    host_project_id = "my-host-project"
    host_folder_id  = "123456789012"
    network_admin_members = [
      "group:network-admins@example.com",
    ]
    service_project_ids = ["svc-project-a", "svc-project-b"]
    subnet_users = {
      "snet-app-shared" = [
        "serviceAccount:111-compute@developer.gserviceaccount.com",
        "serviceAccount:222-compute@developer.gserviceaccount.com",
      ]
      "snet-data-shared" = [
        "serviceAccount:111-compute@developer.gserviceaccount.com",
      ]
    }
  }

  assert {
    condition     = module.shared_vpc.network_name == "shared-vpc"
    error_message = "Shared VPC network name should be shared-vpc"
  }

  assert {
    condition     = length(google_folder_iam_member.xpn_admin) == 1
    error_message = "Expected 1 folder-level xpnAdmin IAM binding"
  }

  assert {
    condition     = length(module.shared_vpc.service_project_ids) == 2
    error_message = "Expected 2 service projects attached to the Shared VPC host"
  }

  assert {
    condition     = length(module.shared_subnets.subnet_iam_members) == 3
    error_message = "Expected 3 IAM member bindings (2 for snet-app-shared, 1 for snet-data-shared)"
  }
}
