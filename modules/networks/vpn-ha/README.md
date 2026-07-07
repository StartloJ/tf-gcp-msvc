<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.10, < 8 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 7.10, < 8 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.39.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_external_vpn_gateway.external_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_external_vpn_gateway) | resource |
| [google_compute_ha_vpn_gateway.ha_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway) | resource |
| [google_compute_router.router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_interface.router_interface](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface) | resource |
| [google_compute_router_peer.bgp_peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer) | resource |
| [google_compute_vpn_tunnel.tunnels](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel) | resource |
| [random_id.secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_create_vpn_gateway"></a> [create\_vpn\_gateway](#input\_create\_vpn\_gateway) | create a VPN gateway | `bool` | `true` | no |
| <a name="input_external_vpn_gateway_description"></a> [external\_vpn\_gateway\_description](#input\_external\_vpn\_gateway\_description) | An optional description of external VPN Gateway | `string` | `"Terraform managed external VPN gateway"` | no |
| <a name="input_keepalive_interval"></a> [keepalive\_interval](#input\_keepalive\_interval) | The interval in seconds between BGP keepalive messages that are sent to the peer. | `number` | `20` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for vpn components | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | VPN gateway name, and prefix used for dependent resources. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | VPC used for the gateway and routes. | `string` | n/a | yes |
| <a name="input_peer_external_gateway"></a> [peer\_external\_gateway](#input\_peer\_external\_gateway) | Configuration of an external VPN gateway to which this VPN is connected. | <pre>object({<br/>    name            = optional(string)<br/>    redundancy_type = optional(string)<br/>    interfaces = list(object({<br/>      id         = number<br/>      ip_address = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_peer_gcp_gateway"></a> [peer\_gcp\_gateway](#input\_peer\_gcp\_gateway) | Self Link URL of the peer side HA GCP VPN gateway to which this VPN tunnel is connected. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project where resources will be created. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region used for resources. | `string` | n/a | yes |
| <a name="input_route_priority"></a> [route\_priority](#input\_route\_priority) | Route priority, defaults to 1000. | `number` | `1000` | no |
| <a name="input_router_advertise_config"></a> [router\_advertise\_config](#input\_router\_advertise\_config) | Router custom advertisement configuration, ip\_ranges is a map of address ranges and descriptions. | <pre>object({<br/>    groups    = list(string)<br/>    ip_ranges = map(string)<br/>    mode      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_router_asn"></a> [router\_asn](#input\_router\_asn) | Router ASN used for auto-created router. | `number` | `64514` | no |
| <a name="input_router_name"></a> [router\_name](#input\_router\_name) | Name of router, leave blank to create one. | `string` | `""` | no |
| <a name="input_stack_type"></a> [stack\_type](#input\_stack\_type) | The IP stack type will apply to all the tunnels associated with this VPN gateway. | `string` | `"IPV4_ONLY"` | no |
| <a name="input_tunnels"></a> [tunnels](#input\_tunnels) | VPN tunnel configurations, bgp\_peer\_options is usually null. | <pre>map(object({<br/>    bgp_peer = object({<br/>      address = string<br/>      asn     = number<br/>    })<br/>    bgp_session_name = optional(string)<br/>    bgp_peer_options = optional(object({<br/>      ip_address          = optional(string)<br/>      advertise_groups    = optional(list(string))<br/>      advertise_ip_ranges = optional(map(string))<br/>      advertise_mode      = optional(string)<br/>      route_priority      = optional(number)<br/>    }))<br/>    bgp_session_range               = optional(string)<br/>    ike_version                     = optional(number)<br/>    vpn_gateway_interface           = optional(number)<br/>    peer_external_gateway_self_link = optional(string, null)<br/>    peer_external_gateway_interface = optional(number)<br/>    shared_secret                   = optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_vpn_gateway_self_link"></a> [vpn\_gateway\_self\_link](#input\_vpn\_gateway\_self\_link) | self\_link of existing VPN gateway to be used for the vpn tunnel. create\_vpn\_gateway should be set to false | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_gateway"></a> [external\_gateway](#output\_external\_gateway) | External VPN gateway resource. |
| <a name="output_gateway"></a> [gateway](#output\_gateway) | HA VPN gateway resource. |
| <a name="output_name"></a> [name](#output\_name) | VPN gateway name. |
| <a name="output_random_secret"></a> [random\_secret](#output\_random\_secret) | Generated secret. |
| <a name="output_router"></a> [router](#output\_router) | Router resource (only if auto-created). |
| <a name="output_router_name"></a> [router\_name](#output\_router\_name) | Router name. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | HA VPN gateway self link. |
| <a name="output_tunnel_names"></a> [tunnel\_names](#output\_tunnel\_names) | VPN tunnel names. |
| <a name="output_tunnel_self_links"></a> [tunnel\_self\_links](#output\_tunnel\_self\_links) | VPN tunnel self links. |
| <a name="output_tunnels"></a> [tunnels](#output\_tunnels) | VPN tunnel resources. |
<!-- END_TF_DOCS -->