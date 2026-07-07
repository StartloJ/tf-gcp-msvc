variable "project_id" {
  description = "The ID of the project where subnets will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the network where subnets will be created"
  type        = string
}

variable "subnets" {
  type = list(object({
    subnet_name                      = string
    subnet_ip                        = string
    subnet_region                    = string
    subnet_private_access            = optional(string, "false")
    subnet_private_ipv6_access       = optional(string)
    subnet_flow_logs                 = optional(string, "false")
    subnet_flow_logs_interval        = optional(string, "INTERVAL_5_SEC")
    subnet_flow_logs_sampling        = optional(string, "0.5")
    subnet_flow_logs_metadata        = optional(string, "INCLUDE_ALL_METADATA")
    subnet_flow_logs_filter          = optional(string, "true")
    subnet_flow_logs_metadata_fields = optional(list(string), [])
    description                      = optional(string)
    purpose                          = optional(string)
    role                             = optional(string)
    stack_type                       = optional(string)
    ipv6_access_type                 = optional(string)
  }))
  description = "The list of subnets being created"
}

variable "secondary_ranges" {
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  description = "Secondary ranges that will be used in some of the subnets"
  default     = {}
}

variable "subnet_users" {
  type        = map(list(string))
  description = "Map of subnet name to list of IAM members granted roles/compute.networkUser on that subnet. Used to delegate subnets to service project identities in a Shared VPC setup. Members must already exist (e.g. 'serviceAccount:sa@project.iam.gserviceaccount.com', 'group:team@domain.com')."
  default     = {}

  validation {
    condition     = alltrue(flatten([for members in values(var.subnet_users) : [for m in members : m != ""]]))
    error_message = "subnet_users must not contain empty member strings."
  }
}