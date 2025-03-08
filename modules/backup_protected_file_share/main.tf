
resource "azurerm_backup_container_storage_account" "container" {

  count = var.backup_protected_file_share.disable_registration == true ? 0 : 1

  resource_group_name       = var.backup_protected_file_share.vault_resource_group_name
  recovery_vault_name       = var.backup_protected_file_share.vault_name
  storage_account_id  = var.backup_protected_file_share.source_storage_account_id
  timeouts {
    create = "60m"
    delete = "60m"
    read   = "10m"
  }
  
}

resource "time_sleep" "wait_pre" {
  create_duration = try(var.backup_protected_file_share.sleep_timer, "60s")

  depends_on = [ azurerm_backup_container_storage_account.container ]
}
resource "azurerm_backup_protected_file_share" "this" {
  resource_group_name       = var.backup_protected_file_share.vault_resource_group_name
  recovery_vault_name       = var.backup_protected_file_share.vault_name
  source_storage_account_id = var.backup_protected_file_share.source_storage_account_id
  source_file_share_name    = var.backup_protected_file_share.source_file_share_name
  backup_policy_id          = var.backup_protected_file_share.backup_policy_id
  timeouts {
    create = "60m"
    delete = "60m"
    read   = "10m"
  }
  

  depends_on = [ time_sleep.wait_pre ]

}