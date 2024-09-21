locals {
  subnets = {
    for x in var.subnets :
    "${x.subnet_region}/${x.subnet_name}" => x
  }
}

/******************************************
	Subnet Blocks
 *****************************************/
resource "google_compute_subnetwork" "subnetwork" {
  for_each = local.subnets

  project                    = var.project_id
  name                       = each.value.subnet_name
  description                = lookup(each.value, "description", null)
  region                     = each.value.subnet_region
  network                    = var.network_name
  ip_cidr_range              = each.value.subnet_ip
  private_ip_google_access   = lookup(each.value, "subnet_private_access", false)
  private_ipv6_google_access = lookup(each.value, "subnet_private_ipv6_access", false)
  purpose                    = lookup(each.value, "purpose", null)
  role                       = lookup(each.value, "role", null)
  stack_type                 = lookup(each.value, "stack_type", null)
  ipv6_access_type           = lookup(each.value, "ipv6_access_type", null)

  dynamic "secondary_ip_range" {
    for_each = contains(keys(var.secondary_ranges), each.value.subnet_name) == true ? var.secondary_ranges[each.value.subnet_name] : []
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = each.value.subnet_flow_logs == "true" ? [1] : []
    content {
      aggregation_interval = each.value.subnet_flow_logs_interval
      filter_expr          = each.value.subnet_flow_logs_filter
      metadata             = each.value.subnet_flow_logs_metadata
      metadata_fields      = each.value.subnet_flow_logs_metadata_fields
      flow_sampling        = each.value.subnet_flow_logs_sampling
    }
  }
}
