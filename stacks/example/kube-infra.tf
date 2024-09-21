locals {
  ingress_ns_name = "ingress-nginx"
}


/****************************************************
    NGINX ingress controller
    Ref: https://cloud.google.com/kubernetes-engine/docs/how-to/external-svc-lb-rbs
****************************************************/

resource "helm_release" "nginx_controller" {
  name       = "ingress-nginx-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  namespace        = local.ingress_ns_name
  create_namespace = true
  lint             = false
  verify           = false

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  set {
    name  = "controller.metrics.enabled"
    value = true
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = google_compute_address.gke_app_lb_ip.address
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Cluster"
  }

  set {
    name  = "controller.service.annotations.cloud\\.google\\.com/l4-rbs"
    value = "enabled"
  }
}
