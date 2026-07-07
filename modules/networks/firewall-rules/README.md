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
| [google_compute_firewall.rules](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.rules_ingress_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | List of egress rules. This will be ignored if variable 'rules' is non-empty | <pre>list(object({<br/>    name                    = string<br/>    description             = optional(string, null)<br/>    disabled                = optional(bool, null)<br/>    priority                = optional(number, null)<br/>    destination_ranges      = optional(list(string), [])<br/>    source_ranges           = optional(list(string), [])<br/>    source_tags             = optional(list(string))<br/>    source_service_accounts = optional(list(string))<br/>    target_tags             = optional(list(string))<br/>    target_service_accounts = optional(list(string))<br/><br/>    allow = optional(list(object({<br/>      protocol = string<br/>      ports    = optional(list(string))<br/>    })), [])<br/>    deny = optional(list(object({<br/>      protocol = string<br/>      ports    = optional(list(string))<br/>    })), [])<br/>    log_config = optional(object({<br/>      metadata = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | List of ingress rules. This will be ignored if variable 'rules' is non-empty | <pre>list(object({<br/>    name                    = string<br/>    description             = optional(string, null)<br/>    disabled                = optional(bool, null)<br/>    priority                = optional(number, null)<br/>    destination_ranges      = optional(list(string), [])<br/>    source_ranges           = optional(list(string), [])<br/>    source_tags             = optional(list(string))<br/>    source_service_accounts = optional(list(string))<br/>    target_tags             = optional(list(string))<br/>    target_service_accounts = optional(list(string))<br/><br/>    allow = optional(list(object({<br/>      protocol = string<br/>      ports    = optional(list(string))<br/>    })), [])<br/>    deny = optional(list(object({<br/>      protocol = string<br/>      ports    = optional(list(string))<br/>    })), [])<br/>    log_config = optional(object({<br/>      metadata = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of the network this set of firewall rules applies to. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project id of the project that holds the network. | `string` | n/a | yes |
| <a name="input_rules"></a> [rules](#input\_rules) | This is DEPRICATED and available for backward compatiblity. Use ingress\_rules and egress\_rules variables. List of custom rule definitions | <pre>list(object({<br/>    name                    = string<br/>    description             = optional(string, null)<br/>    direction               = optional(string, "INGRESS")<br/>    disabled                = optional(bool, null)<br/>    priority                = optional(number, null)<br/>    ranges                  = optional(list(string), [])<br/>    source_tags             = optional(list(string))<br/>    source_service_accounts = optional(list(string))<br/>    target_tags             = optional(list(string))<br/>    target_service_accounts = optional(list(string))<br/><br/>    allow = optional(list(object({<br/>      protocol = string<br/>      ports    = optional(list(string))<br/>    })), [])<br/>    deny = optional(list(object({<br/>      protocol = string<br/>      ports    = optional(list(string))<br/>    })), [])<br/>    log_config = optional(object({<br/>      metadata = string<br/>    }))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_firewall_rules"></a> [firewall\_rules](#output\_firewall\_rules) | The created firewall rule resources |
| <a name="output_firewall_rules_ingress_egress"></a> [firewall\_rules\_ingress\_egress](#output\_firewall\_rules\_ingress\_egress) | The created firewall ingress/egress rule resources |
<!-- END_TF_DOCS -->