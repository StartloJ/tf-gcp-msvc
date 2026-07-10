variable "project_id" {
  type        = string
  description = "The GCP project ID where the secret will be created."
}

# tflint-ignore: terraform_unused_declarations
variable "region" {
  type        = string
  description = "The GCP region. Kept for module interface consistency; Secret Manager uses global automatic replication by default."
  default     = "asia-southeast1"
}

# tflint-ignore: terraform_unused_declarations
variable "org" {
  type        = string
  description = "Organisation abbreviation. Kept for module interface consistency; secret_id is caller-supplied."
}

# tflint-ignore: terraform_unused_declarations
variable "domain" {
  type        = string
  description = "Business domain abbreviation. Kept for module interface consistency; secret_id is caller-supplied."
}

# tflint-ignore: terraform_unused_declarations
variable "env" {
  type        = string
  description = "Environment code. Kept for module interface consistency; secret_id is caller-supplied."
}

# tflint-ignore: terraform_unused_declarations
variable "region_code" {
  type        = string
  description = "Short region code. Kept for module interface consistency; secret_id is caller-supplied."
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to the Secret Manager secret."
  default     = {}
}

variable "secret_id" {
  type        = string
  description = "The ID of the secret resource. Must be unique within the project."
}

variable "replication_policy" {
  type        = string
  description = "Replication policy for the secret. One of: automatic, user-managed."
  default     = "automatic"

  validation {
    condition     = contains(["automatic", "user-managed"], var.replication_policy)
    error_message = "replication_policy must be one of: automatic, user-managed."
  }
}

variable "replication_regions" {
  type        = list(string)
  description = "List of regions for user-managed replication. Required when replication_policy is user-managed."
  default     = []
}

variable "accessor_members" {
  type        = list(string)
  description = "IAM members granted roles/secretmanager.secretAccessor on this secret."
  default     = []
}

variable "initial_value" {
  type        = string
  description = "Optional initial secret value. Sensitive — never output. A version is created only when non-empty; subsequent rotations must be done outside Terraform."
  default     = ""
  sensitive   = true
}
