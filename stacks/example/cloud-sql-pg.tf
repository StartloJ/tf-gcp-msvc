locals {
  sql_pg_name                 = "example-sql-pg"
  sql_pg_version              = "POSTGRES_16"
  sql_pg_master_instance_type = "db-custom-2-7680"
  sql_pg_db_name              = "example-db"
}

# /*******************************************
# *   Cloud SQL PostgreSQL
# *******************************************/
module "example_cloud-sql-pg" {
  source = "../../modules/sql/postgresql"

  name                 = local.sql_pg_name
  project_id           = data.google_project.example.project_id
  random_instance_name = true
  region               = local.default_region
  database_version     = local.sql_pg_version
  deletion_protection  = false

  // Master configuration
  tier                            = local.sql_pg_master_instance_type
  zone                            = local.available_zones[1]
  availability_type               = "ZONAL"
  maintenance_window_day          = 7
  maintenance_window_hour         = 12
  maintenance_window_update_track = "stable"

  database_flags = [
    { name = "autovacuum", value = "off" }
  ]

  user_labels = {
    env = "dev"
    app = "example"
  }

  ip_configuration = {
    ipv4_enabled                                  = true
    require_ssl                                   = false
    private_network                               = module.example_main_vpc.network_self_link
    allocated_ip_range                            = local.private_ip_sql_subnet
    enable_private_path_for_google_cloud_services = true
    authorized_networks                           = []
  }

  db_name      = local.sql_pg_db_name
  db_charset   = "UTF8"
  db_collation = "en_US.UTF8"

  disk_autoresize = false
  disk_size       = 200

  user_name     = "postgres"
  user_password = "2nOgdulVeN"
  root_password = "1VlIWYhpzR"
}