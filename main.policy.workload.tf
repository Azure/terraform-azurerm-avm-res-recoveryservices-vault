
module "recovery_workload_policy" {
  source   = "./modules/workload_policy"
  for_each = var.workload_backup_policy != null ? var.workload_backup_policy : {}

  recovery_vault_name    = azurerm_recovery_services_vault.this.name
  resource_group_name    = azurerm_recovery_services_vault.this.resource_group_name
  workload_backup_policy = each.value
}