mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "kubernetes" {}
mock_provider "helm" {}
mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "1.2.3.4"
      status_code   = 200
    }
  }
}

run "integration_stack_plan_succeeds" {
  command = plan

  override_data {
    target = data.google_project.example
    values = {
      project_id = "test-project"
      name       = "test-project"
      number     = "123456789012"
    }
  }

  override_module {
    target = module.example-gke-private
    outputs = {
      cluster_id                         = "test-cluster-id"
      name                               = "example-gke-private"
      type                               = "PRIVATE"
      location                           = "asia-southeast1"
      region                             = "asia-southeast1"
      zones                              = ["asia-southeast1-a", "asia-southeast1-b", "asia-southeast1-c"]
      endpoint                           = "10.0.0.1"
      endpoint_dns                       = ""
      min_master_version                 = "1.30.3-gke.1639000"
      logging_service                    = "logging.googleapis.com/kubernetes"
      monitoring_service                 = "monitoring.googleapis.com/kubernetes"
      master_authorized_networks_config  = []
      master_version                     = "1.30.3-gke.1639000"
      ca_certificate                     = "dGVzdA=="
      network_policy_enabled             = false
      http_load_balancing_enabled        = true
      horizontal_pod_autoscaling_enabled = true
      vertical_pod_autoscaling_enabled   = false
      node_pools_names                   = ["example-dev-node-pool"]
      node_pools_versions                = ["1.30.3-gke.1639000"]
      identity_namespace                 = "test-project.svc.id.goog"
      tpu_ipv4_cidr_block                = ""
      mesh_certificates_config           = []
      master_ipv4_cidr_block             = "10.186.16.16/28"
      peering_name                       = "gke-n1234567890-peer"
      dns_cache_enabled                  = false
      identity_service_enabled           = false
      intranode_visibility_enabled       = false
      secret_manager_addon_enabled       = false
      fleet_membership                   = ""
      service_account                    = "sa@test-project.iam.gserviceaccount.com"
    }
  }

  assert {
    condition     = google_compute_address.gke_app_lb_ip.name == "examplelb-ip"
    error_message = "Stack plan failed: GKE LB IP resource not found"
  }

  assert {
    condition     = google_compute_address.gke_app_lb_ip.region == "asia-southeast1"
    error_message = "Stack plan failed: GKE LB IP region incorrect"
  }
}
