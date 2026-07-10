variable "project_id" {
  type        = string
  description = "The GCP project ID where logging resources will be created."
}

variable "region" {
  type        = string
  description = "The GCP region for the log bucket storage location."
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
  description = "Labels for this module. Note: log bucket resources do not support labels in provider v7."
  default     = {}
}

variable "log_bucket_suffix" {
  type        = string
  description = "Purpose suffix for the log bucket ID. Full ID: logbkt-<org>-<domain>-<suffix>-<env>-<region_code>."
}

variable "retention_days" {
  type        = number
  description = "Log retention period in days. Logs are locked after this period."
  default     = 30
}

variable "enable_analytics" {
  type        = bool
  description = "When true, enables Log Analytics on the log bucket for BigQuery-like querying."
  default     = false
}

variable "log_sink_filter" {
  type        = string
  description = "Advanced filter for the log sink. Only matching log entries are routed to the log bucket."
  default     = ""
}

variable "metric_descriptors" {
  type = map(object({
    description = string
    metric_kind = string
    value_type  = string
    filter      = string
  }))
  description = "Map of log-based metric name to configuration. metric_kind: DELTA or GAUGE. value_type: INT64 or DOUBLE."
  default     = {}
}

