
module "backup_protected_vm" {
  source = "./modules/backup_protected_vm"

  for_each = try(var.backup_protected_vm != null ? var.backup_protected_vm : {})
  backup_protected_vm = {
    source_vm_id = each.value.source_vm_id
    vm_backup_policy_name = each.value.vm_backup_policy_name
    vault_name = azurerm_recovery_services_vault.this.name
    vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
  }
}

module "backup_protected_file_share" {
  
  source = "./modules/backup_protected_file_share"

  for_each = try(var.backup_protected_file_share != null ? var.backup_protected_file_share : {}) 
    backup_protected_file_share = {
      vault_name = azurerm_recovery_services_vault.this.name
      vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
      source_storage_account_id = each.value.source_storage_account_id
      source_file_share_name    = each.value.source_file_share_name
      backup_file_share_policy_name          = each.value.backup_file_share_policy_name
      disable_registration = false
      sleep_timer = each.value.sleep_timer

    }

    depends_on = [ module.recovery_services_vault_file_share_policy, ] #azurerm_backup_container_storage_account.this ]

}
