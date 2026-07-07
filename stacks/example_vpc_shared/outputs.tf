output "folder_xpn_admin_bindings" {
  value       = google_folder_iam_member.xpn_admin
  description = "Folder-level roles/compute.xpnAdmin IAM bindings granted to network admin members"
}

output "host_project_id" {
  value       = module.shared_vpc.project_id
  description = "Host project ID that owns the Shared VPC"
}

output "network_name" {
  value       = module.shared_vpc.network_name
  description = "Name of the Shared VPC network"
}

output "network_self_link" {
  value       = module.shared_vpc.network_self_link
  description = "Self-link of the Shared VPC (reference this when attaching GKE clusters or Cloud SQL in service projects)"
}

output "service_project_ids" {
  value       = module.shared_vpc.service_project_ids
  description = "Service project IDs attached to this Shared VPC host"
}

output "subnets" {
  value       = module.shared_subnets.subnets
  description = "Subnet resources created in the Shared VPC"
}

output "subnet_self_links" {
  value = {
    for key, subnet in module.shared_subnets.subnets :
    subnet.name => subnet.self_link
  }
  description = "Map of subnet name to self-link — pass these to service project resources (e.g. google_compute_instance.network_interface.subnetwork)"
}

output "subnet_iam_members" {
  value       = module.shared_subnets.subnet_iam_members
  description = "IAM member bindings granting compute.networkUser on delegated subnets"
}
