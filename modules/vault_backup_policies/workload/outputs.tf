output "output_protection_policy" {
  description = "The output protection policy"
  value       = local.backup
}

output "resource" {
  description = "resource Id output"
  value       = var.workload_backup_policy == null ? null : azurerm_backup_policy_vm_workload.this[0]
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "resource Id output"
  value       = var.workload_backup_policy == null ? null : azurerm_backup_policy_vm_workload.this[0].id
}
