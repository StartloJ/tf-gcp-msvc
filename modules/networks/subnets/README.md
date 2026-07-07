<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.10, < 8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_subnetwork.subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | The name of the network where subnets will be created | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project where subnets will be created | `string` | n/a | yes |
| <a name="input_secondary_ranges"></a> [secondary\_ranges](#input\_secondary\_ranges) | Secondary ranges that will be used in some of the subnets | `map(list(object({ range_name = string, ip_cidr_range = string })))` | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The list of subnets being created | <pre>list(object({<br/>    subnet_name                      = string<br/>    subnet_ip                        = string<br/>    subnet_region                    = string<br/>    subnet_private_access            = optional(string, "false")<br/>    subnet_private_ipv6_access       = optional(string)<br/>    subnet_flow_logs                 = optional(string, "false")<br/>    subnet_flow_logs_interval        = optional(string, "INTERVAL_5_SEC")<br/>    subnet_flow_logs_sampling        = optional(string, "0.5")<br/>    subnet_flow_logs_metadata        = optional(string, "INCLUDE_ALL_METADATA")<br/>    subnet_flow_logs_filter          = optional(string, "true")<br/>    subnet_flow_logs_metadata_fields = optional(list(string), [])<br/>    description                      = optional(string)<br/>    purpose                          = optional(string)<br/>    role                             = optional(string)<br/>    stack_type                       = optional(string)<br/>    ipv6_access_type                 = optional(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | The created subnet resources |
<!-- END_TF_DOCS -->