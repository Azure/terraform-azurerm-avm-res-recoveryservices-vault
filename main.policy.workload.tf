module "recovery_workload_policy" {
  source   = "./modules/workload_policy"
  for_each = var.workload_backup_policy != null ? var.workload_backup_policy : {}

  location               = var.location
  recovery_vault_name    = azapi_resource.this.name
  resource_group_name    = var.resource_group_name
  enable_telemetry       = var.enable_telemetry
  workload_backup_policy = each.value
}
