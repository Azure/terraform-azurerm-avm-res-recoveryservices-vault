module "recovery_services_vault_vm_policy" {
  source   = "./modules/virtual_machine_policy"
  for_each = var.vm_backup_policy != null ? var.vm_backup_policy : {}

  recovery_vault_name = azapi_resource.this.name
  resource_group_name = var.resource_group_name
  vm_backup_policy    = each.value
  ignore_body_changes = var.ignore_body_changes.recovery_services_vault_vm_policy
  resource_types      = var.resource_types.recovery_services_vault_vm_policy
  retry               = var.retry
  timeouts            = var.timeouts
  tags                = var.tags
}
