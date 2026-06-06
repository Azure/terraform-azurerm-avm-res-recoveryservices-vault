output "resource" {
  description = "resource Id output"
  value       = azurerm_backup_protected_file_share.this
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "resource Id output"
  value       = azurerm_backup_protected_file_share.this.id
}

output "storage_account_registration_resource_id" {
  description = "The storage account registration resource ID when automatic registration is enabled, otherwise null."
  value       = length(azurerm_backup_container_storage_account.this) == 0 ? null : azurerm_backup_container_storage_account.this[0].id
}
