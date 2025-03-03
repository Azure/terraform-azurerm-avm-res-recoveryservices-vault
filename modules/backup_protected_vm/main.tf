resource "time_sleep" "wait_pre" {
  create_duration = lookup(var.site_recovery_fabric.sleep_timer, "60s")
}
resource "azurerm_backup_protected_vm" "this" {
  resource_group_name = var.backup_protected_vm.vault_resource_group_name
  recovery_vault_name = var.backup_protected_vm.vault_name
  source_vm_id        = var.backup_protected_vm.source_vm_id
  backup_policy_id    = var.backup_protected_vm.backup_policy_id
  
  depends_on          = [time_sleep.wait_pre]
}
