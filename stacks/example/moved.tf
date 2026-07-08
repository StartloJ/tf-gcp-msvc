# Resource rename strategy for US5 naming convention implementation
#
# All resource name ATTRIBUTE values in this stack have been updated to use
# naming locals (locals.tf) in T070. No Terraform module or resource ADDRESS
# renames were made — only the GCP API name arguments changed. Because the
# Terraform resource identifiers are unchanged, no moved {} blocks are required
# to prevent destroy/re-create.
#
# If this stack has been applied and resource names have already been provisioned
# with the old example-* prefix, the resource names WILL change on the next plan.
# To avoid recreation of GCP resources that cannot be renamed in-place, apply
# the plan only after verifying via 'terraform plan' that no unexpected destroys
# appear. Most GCP compute, network, and SQL resources support in-place name
# changes; see contracts/state-migration.md for verification steps.
