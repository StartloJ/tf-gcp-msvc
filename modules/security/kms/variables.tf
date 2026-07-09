variable "project_id" {
  type        = string
  description = "The GCP project ID where the KMS key ring and keys will be created."
}

variable "region" {
  type        = string
  description = "The GCP region where the KMS key ring will be created."
  default     = "asia-southeast1"
}

variable "org" {
  type        = string
  description = "Organisation abbreviation used in resource naming (e.g. obk)."
}

variable "domain" {
  type        = string
  description = "Business domain abbreviation used in resource naming (e.g. ml, data)."
}

variable "env" {
  type        = string
  description = "Environment code used in resource naming. One of: shd, prd, np, sbx."
}

variable "region_code" {
  type        = string
  description = "Short region code used in resource naming (e.g. sg for asia-southeast1)."
}

# tflint-ignore: terraform_unused_declarations
variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources managed by this module. Note: KMS key rings and crypto keys do not support the labels attribute in provider v7."
  default     = {}
}

variable "key_ring_suffix" {
  type        = string
  description = "Purpose suffix used in key ring naming. Full name: kr-<org>-<domain>-<suffix>-<env>-<region_code>."
}

variable "keys" {
  type = map(object({
    rotation_period = string
    algorithm       = string
    purpose         = string
  }))
  description = "Map of crypto key name to configuration. rotation_period in seconds (e.g. '2592000s' for 30 days). algorithm e.g. GOOGLE_SYMMETRIC_ENCRYPTION. purpose e.g. ENCRYPT_DECRYPT."
}

variable "key_iam_bindings" {
  type        = map(list(string))
  description = "Map of crypto key name to list of IAM members granted roles/cloudkms.cryptoKeyEncrypterDecrypter."
  default     = {}
}

variable "prevent_destroy" {
  type        = bool
  description = "When true (default), key rings and crypto keys have prevent_destroy = true in their lifecycle block. Set to false only when decommissioning keys."
  default     = true
}
