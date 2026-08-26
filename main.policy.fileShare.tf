module "recovery_services_vault_file_share_policy" {
  source   = "./modules/file_share_policy"
  for_each = var.file_share_backup_policy != null ? var.file_share_backup_policy : {}

  recovery_vault_name      = azapi_resource.this.name
  resource_group_name      = var.resource_group_name
  file_share_backup_policy = each.value
  ignore_body_changes      = var.ignore_body_changes.recovery_services_vault_file_share_policy
  resource_types           = var.resource_types.recovery_services_vault_file_share_policy
  retry                    = var.retry
  tags                     = var.tags
  timeouts                 = var.timeouts
}
