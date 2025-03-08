
data "azurerm_backup_policy_vm" "this" {
  name                = var.backup_protected_vm.vm_backup_policy_name
  recovery_vault_name = var.backup_protected_vm.vault_name
  resource_group_name = var.backup_protected_vm.vault_resource_group_name
}
