output "example_Vpc" {
  description = "The VPC resource being created"
  value       = module.example_main_vpc
}

output "example_Subnets" {
  description = "The Subnet resource being created"
  value       = module.example_snet
}

output "example_NAT" {
  description = "The Cloud NAT resource being created"
  value       = module.example_nat.name
}

output "example_firewall_rules" {
  description = "The Firewall resource being created"
  value       = module.example_firewall
}

// VPN block
# output "example_VPN" {
#   description = "The VPN resource being created"
#   value       = module.example_vpn_ha_to_onprem
#   sensitive   = true
# }

output "example_VPN_classic" {
  description = "The VPN Classic resource being created"
  value       = module.example_classic_vpn_single
  sensitive   = true
}

output "example_gke_private" {
  description = "The GKE Private resource being created"
  value       = module.example-gke-private
}
