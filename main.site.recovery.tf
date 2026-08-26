module "backup_protected_vm" {
  source   = "./modules/backup_protected_vm"
  for_each = try(var.backup_protected_vm != null ? var.backup_protected_vm : {})

  backup_protected_vm = {
    backup_policy_id = "${azapi_resource.this.id}/backupPolicies/${each.value.vm_backup_policy_name}"
    sleep_timer      = each.value.sleep_timer
    source_vm_id     = each.value.source_vm_id
  }
  ignore_body_changes = var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  parent_id           = "${azapi_resource.this.id}/backupFabrics/Azure/protectionContainers/iaasvmcontainer;iaasvmcontainerv2;${split("/", each.value.source_vm_id)[4]};${basename(each.value.source_vm_id)}"
  resource_types      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  retry               = var.retry
  timeouts            = var.timeouts

  depends_on = [module.recovery_services_vault_vm_policy]
}

module "backup_protected_file_share" {
  source   = "./modules/backup_protected_file_share"
  for_each = try(var.backup_protected_file_share != null ? var.backup_protected_file_share : {})

  backup_protected_file_share = {
    backup_policy_id          = "${azapi_resource.this.id}/backupPolicies/${each.value.backup_file_share_policy_name}"
    disable_registration      = each.value.disable_registration
    sleep_timer               = each.value.sleep_timer
    source_file_share_name    = each.value.source_file_share_name
    source_storage_account_id = each.value.source_storage_account_id
  }
  ignore_body_changes = var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  parent_id           = "${azapi_resource.this.id}/backupFabrics/Azure/protectionContainers/StorageContainer;storage;${split("/", each.value.source_storage_account_id)[4]};${basename(each.value.source_storage_account_id)}"
  resource_types      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  retry               = var.retry
  timeouts            = var.timeouts

  depends_on = [module.recovery_services_vault_file_share_policy]
}

module "site_recovery_replicated_vm" {
  source   = "./modules/site_recovery_replicated_vm"
  for_each = var.site_recovery_replicated_vm != null ? var.site_recovery_replicated_vm : {}

  site_recovery_replicated_vm = {
    managed_disk                           = each.value.managed_disk
    multi_vm_group_name                    = each.value.multi_vm_group_name
    recovery_replication_policy_id         = each.value.recovery_replication_policy_id
    recovery_resource_group_id             = each.value.recovery_resource_group_id
    recovery_storage_account_id            = each.value.recovery_storage_account_id
    recovery_target_disk_encryption_set_id = each.value.recovery_target_disk_encryption_set_id
    source_vm_id                           = each.value.source_vm_id
    target_network_id                      = each.value.target_network_id
    target_protection_container_id         = each.value.target_protection_container_id
    target_recovery_fabric_id              = each.value.target_recovery_fabric_id
    target_resource_group_id               = each.value.target_resource_group_id
    target_resource_id                     = each.value.target_resource_id
    target_static_ip                       = each.value.target_static_ip
    target_subnet_name                     = each.value.target_subnet_name
    target_virtual_machine_size            = each.value.target_virtual_machine_size
    test_network_id                        = each.value.test_network_id
    test_subnet_name                       = each.value.test_subnet_name
    unmanaged_disk                         = each.value.unmanaged_disk
  }
  ignore_body_changes = var.ignore_body_changes.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items
  parent_id           = "${azapi_resource.this.id}/replicationFabrics/${each.value.source_recovery_fabric_name}/replicationProtectionContainers/${each.value.source_protection_container_name}"
  resource_types      = var.resource_types.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items
  retry               = var.retry
  timeouts            = each.value.timeouts == null ? var.timeouts : each.value.timeouts

  depends_on = [azapi_resource.this]
}

module "backup_protected_workload" {
  source   = "./modules/backup_protected_workload"
  for_each = var.backup_protected_workload != null ? var.backup_protected_workload : {}

  backup_protected_workload = {
    vault_id                  = azapi_resource.this.id
    source_vm_id              = each.value.source_vm_id
    workload_backup_policy_id = "${azapi_resource.this.id}/backupPolicies/${each.value.workload_backup_policy_name}"
    workload_type             = each.value.workload_type
    inquiry_enabled           = each.value.inquiry_enabled
    sleep_timer               = each.value.sleep_timer
    protected_databases       = each.value.protected_databases
  }

  depends_on = [module.recovery_workload_policy]
}
