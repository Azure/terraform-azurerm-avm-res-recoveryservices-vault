
module "recovery_services_vault_vm_policy" {
  source   = "./modules/virtual_machine_policy"
  for_each = var.vm_backup_policy != null ? var.vm_backup_policy : {}

  recovery_vault_name = azurerm_recovery_services_vault.this.name
  resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
  vm_backup_policy    = each.value

}