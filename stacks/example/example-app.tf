locals {
  enable_example_api = false
  enable_examplecms  = true
  enable_exampleapi  = false
}

/************************************************
    example application Workspace
************************************************/

resource "kubernetes_namespace" "example-api" {
  metadata {
    name = "example-api"

    labels = {
      name     = "example-api"
      workload = "application"
      env      = "dev"
    }
  }
}

resource "kubernetes_namespace" "example-web" {
  metadata {
    name = "example-web"

    labels = {
      name     = "example-web"
      workload = "application"
      env      = "dev"
    }
  }
}

/************************************************
    Example API
************************************************/
resource "kubernetes_deployment_v1" "simple-api" {
  count = local.enable_example_api ? 1 : 0
  metadata {
    name      = "simple-api"
    namespace = kubernetes_namespace.example-api.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "simple-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "simple-api"
        }
      }
      spec {
        container {
          image = "gcr.io/google_containers/echoserver:1.10"
          name  = "simple-api"
          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "125m"
              memory = "64Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "32Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }

            initial_delay_seconds = 3
            timeout_seconds       = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "simple-api" {
  count = local.enable_example_api ? 1 : 0
  metadata {
    name      = "simple-api"
    namespace = kubernetes_namespace.example-api.metadata[0].name
  }

  spec {
    selector = {
      app = "simple-api"
    }
    session_affinity = "ClientIP"
    type             = "ClusterIP"
    port {
      name = "http"
      port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "simple-api" {
  count = local.enable_example_api ? 1 : 0

  metadata {
    name      = "simple-api"
    namespace = kubernetes_namespace.example-api.metadata[0].name
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.simple-api[0].metadata[0].name
              port {
                name = "http"
              }
            }
          }
          path = "/"
        }
      }
    }
  }
}
