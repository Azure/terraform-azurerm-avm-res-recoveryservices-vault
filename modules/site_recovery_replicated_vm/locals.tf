locals {
  # API version derived from the configured resource type so it cannot drift when a
  # caller overrides `var.resource_types`.
  api_version = split("@", var.resource_types.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items)[1]
  # `site_recovery_replicated_vm.timeouts` is the pre-existing public input and keeps
  # precedence; `var.timeouts` is the TFFR7 fallback for any value it leaves unset.
  effective_timeouts = {
    create = try(coalesce(var.site_recovery_replicated_vm.timeouts.create, var.timeouts.create), null)
    delete = try(coalesce(var.site_recovery_replicated_vm.timeouts.delete, var.timeouts.delete), null)
    read   = try(coalesce(var.site_recovery_replicated_vm.timeouts.read, var.timeouts.read), null)
    update = try(coalesce(var.site_recovery_replicated_vm.timeouts.update, var.timeouts.update), null)
  }
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

  # Azure Site Recovery completes the enable-protection job asynchronously after the
  # PUT returns, and rejects the update contract until that job has succeeded. Retry
  # on that specific failure instead of aborting the apply. Any caller-supplied
  # `var.retry` patterns and intervals are preserved.
  target_settings_retry = {
    error_message_regex = distinct(concat(try(var.retry.error_message_regex, []), [
      "ErrorInVMConfigurationAsProtectionFailed",
      "Ensure that the virtual machine is configured for protection successfully",
    ]))
    interval_seconds     = try(var.retry.interval_seconds, null) != null ? var.retry.interval_seconds : 60
    max_interval_seconds = try(var.retry.max_interval_seconds, null) != null ? var.retry.max_interval_seconds : 300
  }
  # Retrying needs a window long enough for the enable-protection job to finish.
  target_settings_timeouts = {
    create = coalesce(local.effective_timeouts.create, "90m")
    delete = local.effective_timeouts.delete
    read   = local.effective_timeouts.read
    update = coalesce(local.effective_timeouts.update, "90m")
  }
}
