locals {
  # ARM resource type / API version used by this module.
  replication_protected_item_type = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-10-01"
  # The root module only passes the vault name and its resource group, so the vault
  # ARM ID (and therefore the source protection container ID) is rebuilt here from
  # the current AzAPI client configuration.
  vault_id                       = "/subscriptions/${data.azapi_client_config.this.subscription_id}/resourceGroups/${var.site_recovery_replicated_vm.vault_resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.site_recovery_replicated_vm.recovery_vault_name}"
  source_protection_container_id = "${local.vault_id}/replicationFabrics/${var.site_recovery_replicated_vm.source_recovery_fabric_name}/replicationProtectionContainers/${var.site_recovery_replicated_vm.source_protection_container_name}"
  recovery_resource_group_id     = coalesce(var.site_recovery_replicated_vm.target_resource_group_id, var.site_recovery_replicated_vm.recovery_resource_group_id)

  # `managed_disk` -> A2AEnableProtectionInput.vmManagedDisks
  vm_managed_disks = var.site_recovery_replicated_vm.managed_disk == null ? [] : [
    for disk in values(var.site_recovery_replicated_vm.managed_disk) : merge(
      {
        diskId                              = disk.disk_id
        primaryStagingAzureStorageAccountId = disk.staging_storage_account_id
        recoveryResourceGroupId             = disk.target_resource_group_id != null ? disk.target_resource_group_id : local.recovery_resource_group_id
        recoveryTargetDiskAccountType       = disk.target_disk_type
        recoveryReplicaDiskAccountType      = disk.target_replica_disk_type
      },
      (disk.target_disk_encryption_set_id != null ? disk.target_disk_encryption_set_id : var.site_recovery_replicated_vm.recovery_target_disk_encryption_set_id) == null ? {} : {
        recoveryDiskEncryptionSetId = disk.target_disk_encryption_set_id != null ? disk.target_disk_encryption_set_id : var.site_recovery_replicated_vm.recovery_target_disk_encryption_set_id
      }
    )
  ]

  # `unmanaged_disk` -> A2AEnableProtectionInput.vmDisks
  vm_disks = var.site_recovery_replicated_vm.unmanaged_disk == null ? [] : [
    for disk in values(var.site_recovery_replicated_vm.unmanaged_disk) : {
      diskUri                             = disk.disk_uri
      primaryStagingAzureStorageAccountId = disk.staging_storage_account_id != null ? disk.staging_storage_account_id : var.site_recovery_replicated_vm.recovery_storage_account_id
      recoveryAzureStorageAccountId       = disk.target_storage_account_id != null ? disk.target_storage_account_id : var.site_recovery_replicated_vm.recovery_storage_account_id
    }
  ]

  # A2A (Azure to Azure) enable-protection input. Optional members are only sent
  # when set, so that no explicit `null` reaches the REST API.
  provider_specific_details_optional = {
    recoveryContainerId    = var.site_recovery_replicated_vm.target_protection_container_id
    recoveryAzureNetworkId = var.site_recovery_replicated_vm.target_network_id
    recoverySubnetName     = var.site_recovery_replicated_vm.target_subnet_name
    multiVmGroupName       = var.site_recovery_replicated_vm.multi_vm_group_name
  }
  provider_specific_details = merge(
    {
      instanceType            = "A2A"
      fabricObjectId          = var.site_recovery_replicated_vm.source_vm_id
      recoveryResourceGroupId = local.recovery_resource_group_id
    },
    { for key, value in local.provider_specific_details_optional : key => value if value != null },
    length(local.vm_managed_disks) == 0 ? {} : { vmManagedDisks = local.vm_managed_disks },
    length(local.vm_disks) == 0 ? {} : { vmDisks = local.vm_disks }
  )

  # `recoveryAzureVMSize` and `selectedTfoAzureNetworkId` are read-only on the
  # enable-protection (PUT) contract; Azure Site Recovery only accepts them through
  # the update (PATCH) contract once replication has been enabled.
  post_enablement_settings_optional = {
    recoveryAzureVMSize       = var.site_recovery_replicated_vm.target_virtual_machine_size
    selectedTfoAzureNetworkId = var.site_recovery_replicated_vm.test_network_id
  }
  post_enablement_settings = { for key, value in local.post_enablement_settings_optional : key => value if value != null }
}
