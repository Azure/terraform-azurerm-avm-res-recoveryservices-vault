output "resource" {
  description = "The `azapi_resource` object for the Azure Backup protected item (`Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems`). This is an AzAPI resource object, not the legacy AzureRM `azurerm_backup_protected_vm` object."
  value       = azapi_resource.this
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "The ARM resource ID of the Azure Backup protected item."
  value       = azapi_resource.this.id
}
