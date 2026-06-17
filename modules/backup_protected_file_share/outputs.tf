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
