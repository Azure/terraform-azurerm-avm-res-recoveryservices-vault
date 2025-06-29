
resource "azurerm_backup_container_storage_account" "this" {
  count = var.backup_protected_file_share.disable_registration == true ? 0 : 1

  recovery_vault_name = var.backup_protected_file_share.vault_name
  resource_group_name = var.backup_protected_file_share.vault_resource_group_name
  storage_account_id  = var.backup_protected_file_share.source_storage_account_id

  dynamic "timeouts" {
    for_each = var.backup_protected_file_share.timeouts == null ? [] : [var.backup_protected_file_share.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
    }
  }
}

resource "time_sleep" "wait_pre" {
  create_duration = var.backup_protected_file_share.sleep_timer

  depends_on = [azurerm_backup_container_storage_account.this]
}
resource "azurerm_backup_protected_file_share" "this" {
  backup_policy_id          = data.azurerm_backup_policy_file_share.this.id
  recovery_vault_name       = var.backup_protected_file_share.vault_name
  resource_group_name       = var.backup_protected_file_share.vault_resource_group_name
  source_file_share_name    = var.backup_protected_file_share.source_file_share_name
  source_storage_account_id = var.backup_protected_file_share.source_storage_account_id

  dynamic "timeouts" {
    for_each = var.backup_protected_file_share.timeouts == null ? [] : [var.backup_protected_file_share.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
    }
  }

  depends_on = [time_sleep.wait_pre]
}