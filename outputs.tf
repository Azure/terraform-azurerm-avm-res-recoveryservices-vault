output "private_endpoints" {
  description = <<DESCRIPTION
  A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource" {
  description = "resource Id output"
  value       = azurerm_recovery_services_vault.this
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "resource Id output"
  value       = azurerm_recovery_services_vault.this.id
}

# child-module policy outputs
output "recovery_services_vault_vm_policy" {
  description = "recovery_services_vault_vm_policy"
  value       = module.recovery_services_vault_vm_policy
}

output "recovery_services_vault_file_share_policy" {
  description = "recovery_services_vault_file_share_policy"
  value       = module.recovery_services_vault_file_share_policy
}

output "recovery_workload_policy" {
  description = "recovery_workload_policy"
  value       = module.recovery_workload_policy
}

output "backup_protected_vm" {
  description = "backup_protected_vm"
  value       = module.backup_protected_vm
}

output "backup_protected_file_share" {
  description = "backup_protected_file_share"
  value       = module.backup_protected_file_share
}
