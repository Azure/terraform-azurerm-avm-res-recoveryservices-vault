output "body" {
  description = "The configured AzAPI request body sent to Azure for the workload backup policy, or `null` when no policy is created."
  value       = var.workload_backup_policy == null ? null : azapi_resource.this[0].body
}

output "name" {
  description = "The name of the workload backup policy, or `null` when no policy is created."
  value       = var.workload_backup_policy == null ? null : azapi_resource.this[0].name
}

output "output_protection_policy" {
  description = "The output protection policy"
  value       = local.backup
}

output "resource_id" {
  description = "The resource ID of the workload backup policy, or `null` when no policy is created."
  value       = var.workload_backup_policy == null ? null : azapi_resource.this[0].id
}
