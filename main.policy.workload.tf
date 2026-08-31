module "recovery_workload_policy" {
  source   = "./modules/workload_policy"
  for_each = var.workload_backup_policy != null ? var.workload_backup_policy : {}

  recovery_vault_name    = azapi_resource.this.name
  resource_group_name    = var.resource_group_name
  ignore_body_changes    = var.ignore_body_changes.recovery_workload_policy
  resource_types         = var.resource_types.recovery_workload_policy
  retry                  = var.retry
  timeouts               = var.timeouts
  workload_backup_policy = each.value
}
