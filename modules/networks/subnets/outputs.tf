output "subnets" {
  value       = google_compute_subnetwork.subnetwork
  description = "The created subnet resources"
}

output "subnet_iam_members" {
  value       = google_compute_subnetwork_iam_member.subnet_users
  description = "IAM member bindings granting compute.networkUser on delegated subnets"
}