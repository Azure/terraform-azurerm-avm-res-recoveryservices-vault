module "backup_protected_vm" {
  source   = "./modules/backup_protected_vm"
  for_each = try(var.backup_protected_vm != null ? var.backup_protected_vm : {})

  backup_protected_vm = {
    source_vm_id              = each.value.source_vm_id
    vm_backup_policy_name     = each.value.vm_backup_policy_name
    vault_name                = azapi_resource.this.name
    vault_resource_group_name = var.resource_group_name
  }

  depends_on = [module.recovery_services_vault_vm_policy]
}

module "backup_protected_file_share" {
  source   = "./modules/backup_protected_file_share"
  for_each = try(var.backup_protected_file_share != null ? var.backup_protected_file_share : {})

  backup_protected_file_share = {
    vault_name                    = azapi_resource.this.name
    vault_resource_group_name     = var.resource_group_name
    source_storage_account_id     = each.value.source_storage_account_id
    source_file_share_name        = each.value.source_file_share_name
    backup_file_share_policy_name = each.value.backup_file_share_policy_name
    disable_registration          = each.value.disable_registration
    sleep_timer                   = each.value.sleep_timer

  }

  depends_on = [module.recovery_services_vault_file_share_policy, ]
}

module "site_recovery_replicated_vm" {
  source   = "./modules/site_recovery_replicated_vm"
  for_each = var.site_recovery_replicated_vm != null ? var.site_recovery_replicated_vm : {}

  site_recovery_replicated_vm = {
    source_vm_id                     = each.value.source_vm_id
    recovery_vault_name              = azapi_resource.this.name
    vault_resource_group_name        = var.resource_group_name
    source_recovery_fabric_name      = each.value.source_recovery_fabric_name
    source_protection_container_name = each.value.source_protection_container_name
    recovery_replication_policy_id   = each.value.recovery_replication_policy_id
    target_resource_id               = each.value.target_resource_id
    target_recovery_fabric_id        = each.value.target_recovery_fabric_id
    target_protection_container_id   = each.value.target_protection_container_id
    managed_disk                     = each.value.managed_disk
    unmanaged_disk                   = each.value.unmanaged_disk
    target_network_id                = each.value.target_network_id
    target_subnet_name               = each.value.target_subnet_name
    target_static_ip                 = each.value.target_static_ip
    test_network_id                  = each.value.test_network_id
    test_subnet_name                 = each.value.test_subnet_name
    recovery_resource_group_id       = each.value.recovery_resource_group_id
    recovery_storage_account_id      = each.value.recovery_storage_account_id
    recovery_target_disk_encryption_set_id = each.value.recovery_target_disk_encryption_set_id
    multi_vm_group_name              = each.value.multi_vm_group_name
    multi_vm_group_create_option     = each.value.multi_vm_group_create_option
    tags                             = each.value.tags
    timeouts                         = each.value.timeouts
  }
}
