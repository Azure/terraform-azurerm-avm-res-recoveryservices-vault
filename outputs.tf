output "backup_protected_vm" {
  description = "Resource ID of the workload backup policy"
  value       = module.backup_protected_vm
}

output "name" {
  description = "The name of the Recovery Services Vault."
  value       = azapi_resource.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire `azapi_resource` (`Microsoft.Network/privateEndpoints`) resource.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azapi_resource.this_managed_dns_zone_groups : azapi_resource.this_unmanaged_dns_zone_groups
}

output "provisioning_state" {
  description = "The provisioning state of the Recovery Services Vault, as returned by Azure."
  value       = try(azapi_resource.this.output.properties.provisioningState, null)
}

output "recovery_services_vault_file_share_policy" {
  description = "Resource ID of the file share backup policy"
  value       = module.recovery_services_vault_file_share_policy
}

output "recovery_services_vault_resource_guard_association_resource_id" {
  description = "The resource ID of the Resource Guard association for the Recovery Services Vault, or `null` when `var.resource_guard_id` is not supplied."
  value       = try(azapi_resource.resource_guard_association[0].id, null)
}

output "recovery_services_vault_vm_policy" {
  description = "Resource ID of the VM backup policy"
  value       = module.recovery_services_vault_vm_policy
}

output "recovery_workload_policy" {
  description = "Resource ID of the VM backup policy"
  value       = module.recovery_workload_policy
}

# Discrete computed outputs are preferred over a whole-resource output.
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "resource Id output"
  value       = azapi_resource.this.id
}

output "site_recovery_replicated_vm" {
  description = "The site recovery replicated VM resources"
  value       = module.site_recovery_replicated_vm
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of the system assigned managed identity of the Recovery Services Vault, or `null` when no system assigned identity is enabled."
  value       = try(azapi_resource.this.output.identity.principalId, null)
}
