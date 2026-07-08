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
  nat_name    = "nat-${var.org}-${var.domain}-egress-${var.env}-${var.region_code}-01"
  router_name = "cr-${var.org}-${var.domain}-nat-${var.env}-${var.region_code}-01"
  sql_name    = "sql-${var.org}-${var.domain}-${var.db_engine}-${var.env}-${var.region_code}"
  ar_name     = "ar-${var.org}-${var.domain}-${var.artifact_type}-${var.env}-${var.region_code}"
}
