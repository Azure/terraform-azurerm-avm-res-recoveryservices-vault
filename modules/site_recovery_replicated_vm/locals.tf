locals {
  managed_disks = [
    for disk in values(coalesce(var.site_recovery_replicated_vm.managed_disk, {})) : merge(
      {
        diskId                              = disk.disk_id
        primaryStagingAzureStorageAccountId = disk.staging_storage_account_id
        recoveryReplicaDiskAccountType      = disk.target_replica_disk_type
        recoveryResourceGroupId             = coalesce(disk.target_resource_group_id, var.site_recovery_replicated_vm.target_resource_group_id, var.site_recovery_replicated_vm.recovery_resource_group_id)
        recoveryTargetDiskAccountType       = disk.target_disk_type
      },
      try(coalesce(disk.target_disk_encryption_set_id, var.site_recovery_replicated_vm.recovery_target_disk_encryption_set_id), null) == null ? {} : {
        recoveryDiskEncryptionSetId = coalesce(disk.target_disk_encryption_set_id, var.site_recovery_replicated_vm.recovery_target_disk_encryption_set_id)
      },
    )
  ]
  managed_disk_updates = [
    for disk in values(coalesce(var.site_recovery_replicated_vm.managed_disk, {})) : {
      diskId                         = disk.disk_id
      recoveryReplicaDiskAccountType = disk.target_replica_disk_type
      recoveryTargetDiskAccountType  = disk.target_disk_type
    }
  ]
  resource_id              = "${var.parent_id}/replicationProtectedItems/${local.resource_name}"
  resource_name            = basename(var.site_recovery_replicated_vm.source_vm_id)
  target_resource_name     = var.site_recovery_replicated_vm.target_resource_id == null ? null : basename(var.site_recovery_replicated_vm.target_resource_id)
  target_resource_group_id = coalesce(var.site_recovery_replicated_vm.target_resource_group_id, var.site_recovery_replicated_vm.recovery_resource_group_id)
  unmanaged_disks = [
    for disk in values(coalesce(var.site_recovery_replicated_vm.unmanaged_disk, {})) : {
      diskUri                             = disk.disk_uri
      primaryStagingAzureStorageAccountId = try(coalesce(disk.staging_storage_account_id, var.site_recovery_replicated_vm.recovery_storage_account_id), null)
      recoveryAzureStorageAccountId       = try(coalesce(disk.target_storage_account_id, var.site_recovery_replicated_vm.recovery_storage_account_id), null)
    }
  ]
  update_required = (
    var.site_recovery_replicated_vm.target_network_id != null ||
    var.site_recovery_replicated_vm.test_network_id != null ||
    var.site_recovery_replicated_vm.target_virtual_machine_size != null ||
    length(local.managed_disk_updates) > 0
  )
}
