locals {
  common_labels = {
    org          = var.org
    landing_zone = "gcp_lz"
    env          = var.env
    domain       = var.domain
    app          = var.app
    component    = var.component
    owner_team   = var.owner_team
    cost_center  = var.cost_center
    managed_by   = "terraform"
    data_class   = var.data_class
  }

  vpc_name    = "vpc-${var.org}-${var.purpose}-${var.env}"
  subnet_name = "snet-${var.org}-${var.domain}-${var.env}-${var.region_code}"
}
