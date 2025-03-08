
data "azurerm_backup_policy_file_share" "this" {
  name                = var.backup_protected_file_share.backup_file_share_policy_name
  recovery_vault_name = var.backup_protected_file_share.vault_name
  resource_group_name = var.backup_protected_file_share.vault_resource_group_name
}
