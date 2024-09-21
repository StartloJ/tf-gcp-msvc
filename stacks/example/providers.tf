provider "google" {
  project = "example"
  region  = "asia-southeast1"
  zone    = "asia-southeast1-b"
}

provider "kubernetes" {
  host                   = "https://${module.example-gke-private.endpoint}"
  token                  = data.google_client_config.dev.access_token
  cluster_ca_certificate = base64decode(module.example-gke-private.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.example-gke-private.endpoint}"
    token                  = data.google_client_config.dev.access_token
    cluster_ca_certificate = base64decode(module.example-gke-private.ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}