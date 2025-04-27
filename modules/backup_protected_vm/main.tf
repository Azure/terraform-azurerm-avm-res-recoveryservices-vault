resource "time_sleep" "wait_pre" {
  create_duration = lookup(var.backup_protected_vm.sleep_timer, "60s")
}
resource "azurerm_backup_protected_vm" "this" {
  recovery_vault_name = var.backup_protected_vm.vault_name
  resource_group_name = var.backup_protected_vm.vault_resource_group_name
  backup_policy_id    = var.backup_protected_vm.backup_policy_id
  source_vm_id        = var.backup_protected_vm.source_vm_id

  dynamic "timeouts" {
    for_each = var.backup_protected_vm.timeouts == null ? [] : [var.backup_protected_vm.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
    }
  }

  depends_on = [time_sleep.wait_pre]
}
