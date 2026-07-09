# AI/ML platform modules — example usage demonstrating all 13 new modules.
# All module calls use local.common_labels for consistent resource tagging.
# Replace placeholder values (project_id, subnet references, image URIs, etc.)
# with environment-specific values via tfvars or a data source.

locals {
  project_id  = var.org == "example" ? "example-project-id" : "REPLACE_WITH_PROJECT_ID"
  region      = "asia-southeast1"
  vpc_id      = "projects/${local.project_id}/global/networks/${local.vpc_name}"
  subnet_id   = "projects/${local.project_id}/regions/${local.region}/subnetworks/${local.subnet_name}"
}

# --------------------------------------------------------------------------
# US1: Data Processing & Storage
# --------------------------------------------------------------------------

module "dataproc" {
  source = "../../modules/data/dataproc"

  project_id          = local.project_id
  region              = local.region
  org                 = var.org
  domain              = var.domain
  env                 = var.env
  region_code         = var.region_code
  cluster_name_suffix = "etl"
  subnet_name         = local.subnet_id
  labels              = local.common_labels

  master_machine_type = "n2-standard-4"
  worker_machine_type = "n2-standard-8"
  worker_count        = 2

  enable_dr_standby = false
}

module "bigquery" {
  source = "../../modules/data/bigquery"

  project_id        = local.project_id
  region            = local.region
  org               = var.org
  domain            = var.domain
  env               = var.env
  region_code       = var.region_code
  dataset_id_suffix = "features"
  labels            = local.common_labels
}

module "gcs" {
  source = "../../modules/storage/gcs"

  project_id         = local.project_id
  region             = local.region
  org                = var.org
  domain             = var.domain
  env                = var.env
  region_code        = var.region_code
  bucket_name_suffix = "models"
  unique_suffix      = "a1b2"
  labels             = local.common_labels
}

# --------------------------------------------------------------------------
# US2: Secret Management & Security
# --------------------------------------------------------------------------

module "secret_manager" {
  source = "../../modules/security/secret-manager"

  project_id  = local.project_id
  region      = local.region
  org         = var.org
  domain      = var.domain
  env         = var.env
  region_code = var.region_code
  secret_id   = "${var.domain}-api-key"
  labels      = local.common_labels
}

module "kms" {
  source = "../../modules/security/kms"

  project_id      = local.project_id
  region          = local.region
  org             = var.org
  domain          = var.domain
  env             = var.env
  region_code     = var.region_code
  key_ring_suffix = "data"
  labels          = local.common_labels

  keys = {
    cmek = {
      rotation_period = "2592000s"
      algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
      purpose         = "ENCRYPT_DECRYPT"
    }
  }
}

module "dlp" {
  source = "../../modules/security/dlp"

  project_id                       = local.project_id
  region                           = local.region
  org                              = var.org
  domain                           = var.domain
  env                              = var.env
  region_code                      = var.region_code
  inspection_template_display_name = "PII Scanner — ${var.domain}"
  info_types                       = ["EMAIL_ADDRESS", "CREDIT_CARD_NUMBER", "PHONE_NUMBER"]
  labels                           = local.common_labels
}

module "dataplex" {
  source = "../../modules/governance/dataplex"

  project_id       = local.project_id
  region           = local.region
  org              = var.org
  domain           = var.domain
  env              = var.env
  region_code      = var.region_code
  lake_name_suffix = "platform"
  labels           = local.common_labels

  zones = {
    raw = {
      type          = "RAW"
      asset_buckets = [module.gcs.bucket_name]
    }
  }
}

# --------------------------------------------------------------------------
# US3: Network Infrastructure
# --------------------------------------------------------------------------

module "psc" {
  source = "../../modules/networks/psc"

  project_id  = local.project_id
  region      = local.region
  org         = var.org
  domain      = var.domain
  env         = var.env
  region_code = var.region_code
  network_id  = local.vpc_id
  psc_type    = "google-apis"
  labels      = local.common_labels
}

module "load_balancer" {
  source = "../../modules/networks/load-balancer"

  project_id  = local.project_id
  region      = local.region
  org         = var.org
  domain      = var.domain
  env         = var.env
  region_code = var.region_code
  labels      = local.common_labels

  load_balancer_type    = "external-global"
  ssl_certificate_domains = ["${var.domain}.example.com"]

  backend_service_backends = [
    {
      group          = "projects/${local.project_id}/regions/${local.region}/networkEndpointGroups/REPLACE_NEG_NAME"
      balancing_mode = "RATE"
    }
  ]
}

module "secure_web_proxy" {
  source = "../../modules/networks/secure-web-proxy"

  project_id  = local.project_id
  region      = local.region
  org         = var.org
  domain      = var.domain
  env         = var.env
  region_code = var.region_code
  network_id  = local.vpc_id
  subnet_cidr = "10.128.0.0/26"
  labels      = local.common_labels

  allowed_url_patterns = [
    "*.googleapis.com",
    "pypi.org",
    "files.pythonhosted.org"
  ]
  default_action = "deny"
}

# --------------------------------------------------------------------------
# US4: Workload & API Management
# --------------------------------------------------------------------------

module "cloud_run" {
  source = "../../modules/workload/cloud-run"

  project_id          = local.project_id
  region              = local.region
  org                 = var.org
  domain              = var.domain
  env                 = var.env
  region_code         = var.region_code
  service_name_suffix = "inference"
  container_image     = "asia-docker.pkg.dev/${local.project_id}/models/inference:latest"
  labels              = local.common_labels

  allow_unauthenticated = false
  min_instances         = var.env == "prd" ? 1 : 0
  max_instances         = 10
  cpu                   = "2"
  memory                = "2Gi"
}

module "api_gateway" {
  source = "../../modules/api/api-gateway"

  project_id               = local.project_id
  region                   = local.region
  org                      = var.org
  domain                   = var.domain
  env                      = var.env
  region_code              = var.region_code
  api_id_suffix            = "inference"
  gateway_config_id_suffix = "inference"
  labels                   = local.common_labels

  openapi_spec = <<-YAML
    swagger: "2.0"
    info:
      title: Inference API
      version: "1.0.0"
    host: "REPLACE_WITH_GATEWAY_HOST"
    schemes:
      - https
    paths:
      /predict:
        post:
          operationId: predict
          responses:
            "200":
              description: Prediction result
    x-google-backend:
      address: ${module.cloud_run.service_url}
  YAML
}

module "cloud_endpoints" {
  source = "../../modules/api/cloud-endpoints"

  project_id   = local.project_id
  region       = local.region
  org          = var.org
  domain       = var.domain
  env          = var.env
  region_code  = var.region_code
  service_name = "${var.domain}-api.endpoints.${local.project_id}.cloud.goog"
  labels       = local.common_labels

  openapi_spec = <<-YAML
    swagger: "2.0"
    info:
      title: ${var.domain} API
      version: "1.0.0"
    host: "${var.domain}-api.endpoints.${local.project_id}.cloud.goog"
    paths: {}
  YAML
}

# --------------------------------------------------------------------------
# US5: Observability (with DR validation)
# --------------------------------------------------------------------------

module "cloud_logging" {
  source = "../../modules/observability/cloud-logging"

  project_id        = local.project_id
  region            = local.region
  org               = var.org
  domain            = var.domain
  env               = var.env
  region_code       = var.region_code
  log_bucket_suffix = "platform"
  labels            = local.common_labels

  retention_days   = 90
  enable_analytics = true
}
