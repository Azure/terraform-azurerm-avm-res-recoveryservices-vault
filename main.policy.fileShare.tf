
module "recovery_services_vault_file_share_policy" {
  source   = "./modules/vault_backup_policies/file_share"
  for_each = var.file_share_backup_policy != null ? var.file_share_backup_policy : {}

  recovery_vault_name      = azurerm_recovery_services_vault.this.name
  resource_group_name      = azurerm_recovery_services_vault.this.resource_group_name
  file_share_backup_policy = each.value

}