# Site Recovery creates a replicated item with PUT but removes it with
# POST /remove. Action resources model those asymmetric operations without
# issuing an unsupported generic DELETE request.
resource "azapi_resource_action" "this" {
  type        = var.resource_types.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items
  resource_id = local.resource_id
  action      = ""
  method      = "PUT"
  body = {
    properties = {
      policyId = var.site_recovery_replicated_vm.recovery_replication_policy_id
      providerSpecificDetails = merge(
        {
          fabricObjectId          = var.site_recovery_replicated_vm.source_vm_id
          instanceType            = "A2A"
          recoveryContainerId     = var.site_recovery_replicated_vm.target_protection_container_id
          recoveryResourceGroupId = local.target_resource_group_id
        },
        var.site_recovery_replicated_vm.multi_vm_group_name == null ? {} : {
          multiVmGroupName = var.site_recovery_replicated_vm.multi_vm_group_name
        },
        var.site_recovery_replicated_vm.target_network_id == null ? {} : {
          recoveryAzureNetworkId = var.site_recovery_replicated_vm.target_network_id
        },
        var.site_recovery_replicated_vm.target_subnet_name == null ? {} : {
          recoverySubnetName = var.site_recovery_replicated_vm.target_subnet_name
        },
        length(local.unmanaged_disks) == 0 ? {} : {
          vmDisks = local.unmanaged_disks
        },
        length(local.managed_disks) == 0 ? {} : {
          vmManagedDisks = local.managed_disks
        },
      )
    }
  }
  when = "apply"

  response_export_values = ["*"]
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

# Azure Site Recovery accepts target network and VM settings only after initial
# protection has completed. Retry settings can be used to cover that readiness window.
resource "azapi_update_resource" "configuration" {
  count = local.update_required ? 1 : 0

  type        = var.resource_types.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items
  resource_id = local.resource_id
  body = {
    properties = merge(
      {
        providerSpecificDetails = merge(
          {
            instanceType = "A2A"
          },
          length(local.managed_disk_updates) == 0 ? {} : {
            managedDiskUpdateDetails = local.managed_disk_updates
          },
        )
        recoveryAzureVMName = local.target_resource_name
      },
      var.site_recovery_replicated_vm.target_virtual_machine_size == null ? {} : {
        recoveryAzureVMSize = var.site_recovery_replicated_vm.target_virtual_machine_size
      },
      var.site_recovery_replicated_vm.target_network_id == null ? {} : {
        selectedRecoveryAzureNetworkId = var.site_recovery_replicated_vm.target_network_id
      },
      var.site_recovery_replicated_vm.test_network_id == null ? {} : {
        selectedTfoAzureNetworkId = var.site_recovery_replicated_vm.test_network_id
      },
    )
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [azapi_resource_action.this]
}

resource "azapi_resource_action" "remove" {
  type        = var.resource_types.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items
  resource_id = local.resource_id
  action      = "remove"
  method      = "POST"
  body = {
    properties = {
      disableProtectionReason = "NotSpecified"
      replicationProviderInput = {
        instanceType = "DisableProtectionProviderSpecificInput"
      }
    }
  }
  when = "destroy"

  ignore_not_found       = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource_action.this,
    azapi_update_resource.configuration,
  ]
}
