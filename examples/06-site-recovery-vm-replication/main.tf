data "azapi_client_config" "current" {}

resource "random_integer" "region_seed" {
  max = 99999999
  min = 10000000
}

resource "random_string" "storage_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "random_password" "vm_admin" {
  length           = 20
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "random_uuid" "storage_account_contributor_assignment" {}

resource "random_uuid" "storage_blob_data_contributor_assignment" {}

resource "random_uuid" "storage_queue_data_contributor_assignment" {}

locals {
  primary_vault_name   = "rsv-site-recovery-primary-${random_integer.region_seed.result}"
  secondary_vault_name = "rsv-site-recovery-secondary-${random_integer.region_seed.result}"

  source_vms = var.source_vms

  source_vm_data_disks = merge([
    for vm_key, vm in local.source_vms : {
      for disk_key, disk in vm.data_disks : "${vm_key}-${disk_key}" => {
        disk_key = disk_key
        lun      = disk.lun
        size_gb  = disk.size_gb
        vm_key   = vm_key
      }
    }
  ]...)
}

resource "azapi_resource" "resource_group_source" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-site-recovery-${random_integer.region_seed.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "westus2"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_target" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-site-recovery-target-${random_integer.region_seed.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "westcentralus"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_source" {
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  name      = "vnet-source-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  location  = azapi_resource.resource_group_source.location

  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.10.0.0/16"]
      }
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_target" {
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  name      = "vnet-target-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_target.id
  location  = azapi_resource.resource_group_target.location

  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.20.0.0/16"]
      }
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_source" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = "snet-source"
  parent_id = azapi_resource.virtual_network_source.id

  body = {
    properties = {
      addressPrefix = "10.10.1.0/24"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_target" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = "snet-target"
  parent_id = azapi_resource.virtual_network_target.id

  body = {
    properties = {
      addressPrefix = "10.20.1.0/24"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "network_interface_source" {
  for_each = local.source_vms

  type      = "Microsoft.Network/networkInterfaces@2024-05-01"
  name      = "nic-${each.key}-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  location  = azapi_resource.resource_group_source.location

  body = {
    properties = {
      ipConfigurations = [
        {
          name = "ipconfig1"
          properties = {
            privateIPAllocationMethod = "Dynamic"
            subnet = {
              id = azapi_resource.subnet_source.id
            }
          }
        },
      ]
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "managed_disk_source" {
  for_each = local.source_vm_data_disks

  type      = "Microsoft.Compute/disks@2024-03-02"
  name      = "disk-source-${each.value.vm_key}-${each.value.disk_key}-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  location  = azapi_resource.resource_group_source.location

  body = {
    properties = {
      creationData = {
        createOption = "Empty"
      }
      diskSizeGB = each.value.size_gb
    }
    sku = {
      name = "Premium_LRS"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_machine_source" {
  for_each = local.source_vms

  type      = "Microsoft.Compute/virtualMachines@2024-07-01"
  name      = "vm-source-${each.key}-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  location  = azapi_resource.resource_group_source.location

  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      hardwareProfile = {
        vmSize = var.source_vm_size
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.network_interface_source[each.key].id
            properties = {
              primary = true
            }
          },
        ]
      }
      osProfile = {
        adminUsername = "azureadmin"
        computerName  = substr(replace("src-${each.key}-${random_integer.region_seed.result}", "-", ""), 0, 15)
      }
      storageProfile = {
        dataDisks = [
          for disk_key, disk in each.value.data_disks : {
            caching      = "ReadWrite"
            createOption = "Attach"
            lun          = disk.lun
            managedDisk = {
              id = azapi_resource.managed_disk_source["${each.key}-${disk_key}"].id
            }
            name = azapi_resource.managed_disk_source["${each.key}-${disk_key}"].name
          }
        ]
        imageReference = {
          offer     = "WindowsServer"
          publisher = "MicrosoftWindowsServer"
          sku       = "2022-datacenter-azure-edition"
          version   = "latest"
        }
        osDisk = {
          caching      = "ReadWrite"
          createOption = "FromImage"
          managedDisk = {
            storageAccountType = "Premium_LRS"
          }
        }
      }
    }
  }

  sensitive_body = {
    properties = {
      osProfile = {
        adminPassword = random_password.vm_admin.result
      }
    }
  }

  response_export_values = [
    "properties.storageProfile.osDisk.managedDisk.id",
  ]
}

resource "azapi_resource" "storage_account_staging" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = "stasr${random_integer.region_seed.result}${random_string.storage_suffix.result}"
  parent_id = azapi_resource.resource_group_source.id
  location  = azapi_resource.resource_group_source.location

  body = {
    kind = "StorageV2"
    properties = {
      allowBlobPublicAccess = false
      allowSharedKeyAccess  = false
      publicNetworkAccess   = "Enabled"
    }
    sku = {
      name = "Standard_GRS"
    }
  }

  response_export_values = ["*"]
}

# Recovery Services Vault with Site Recovery VM replication enabled.
module "recovery_services_vault_primary" {
  source = "../../"

  location            = azapi_resource.resource_group_target.location
  name                = local.primary_vault_name
  resource_group_name = azapi_resource.resource_group_target.name
  sku                 = "RS0"
  managed_identities = {
    system_assigned = true
  }
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
}

module "recovery_services_vault_secondary" {
  source = "../../"

  location                                       = azapi_resource.resource_group_source.location
  name                                           = local.secondary_vault_name
  resource_group_name                            = azapi_resource.resource_group_source.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
}

resource "azapi_resource" "storage_account_contributor_assignment" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.storage_account_contributor_assignment.result
  parent_id = azapi_resource.storage_account_staging.id

  body = {
    properties = {
      principalId      = module.recovery_services_vault_primary.resource.output.identity.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "storage_blob_data_contributor_assignment" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.storage_blob_data_contributor_assignment.result
  parent_id = azapi_resource.storage_account_staging.id

  body = {
    properties = {
      principalId      = module.recovery_services_vault_primary.resource.output.identity.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "storage_queue_data_contributor_assignment" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.storage_queue_data_contributor_assignment.result
  parent_id = azapi_resource.storage_account_staging.id

  body = {
    properties = {
      principalId      = module.recovery_services_vault_primary.resource.output.identity.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/974c5e8b-45b9-4653-ba55-5f855dd0fb88"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_fabric_primary" {
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics@2024-10-01"
  name      = "fabric-primary-${random_integer.region_seed.result}"
  parent_id = module.recovery_services_vault_primary.resource_id

  body = {
    properties = {
      customDetails = {
        instanceType = "Azure"
        location     = azapi_resource.resource_group_source.location
      }
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_fabric_secondary" {
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics@2024-10-01"
  name      = "fabric-secondary-${random_integer.region_seed.result}"
  parent_id = module.recovery_services_vault_primary.resource_id

  body = {
    properties = {
      customDetails = {
        instanceType = "Azure"
        location     = azapi_resource.resource_group_target.location
      }
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_protection_container_primary" {
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers@2024-10-01"
  name      = "pc-primary-${random_integer.region_seed.result}"
  parent_id = azapi_resource.site_recovery_fabric_primary.id

  body = {
    properties = {}
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_protection_container_secondary" {
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers@2024-10-01"
  name      = "pc-secondary-${random_integer.region_seed.result}"
  parent_id = azapi_resource.site_recovery_fabric_secondary.id

  body = {
    properties = {}
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_replication_policy" {
  type      = "Microsoft.RecoveryServices/vaults/replicationPolicies@2024-10-01"
  name      = "replication-policy-${random_integer.region_seed.result}"
  parent_id = module.recovery_services_vault_primary.resource_id

  body = {
    properties = {
      providerSpecificInput = {
        appConsistentFrequencyInMinutes = 240
        instanceType                    = "A2A"
        multiVmSyncStatus               = "Enable"
        recoveryPointHistory            = 1440
      }
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_protection_container_mapping" {
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectionContainerMappings@2024-10-01"
  name      = "pcm-primary-secondary-${random_integer.region_seed.result}"
  parent_id = azapi_resource.site_recovery_protection_container_primary.id

  body = {
    properties = {
      policyId                    = azapi_resource.site_recovery_replication_policy.id
      targetProtectionContainerId = azapi_resource.site_recovery_protection_container_secondary.id
      providerSpecificInput = {
        instanceType = "A2A"
      }
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_network_mapping" {
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationNetworks/replicationNetworkMappings@2024-10-01"
  name      = "nm-primary-secondary-${random_integer.region_seed.result}"
  parent_id = "${azapi_resource.site_recovery_fabric_primary.id}/replicationNetworks/${azapi_resource.virtual_network_source.name}"

  body = {
    properties = {
      fabricSpecificDetails = {
        instanceType     = "AzureToAzure"
        primaryNetworkId = azapi_resource.virtual_network_source.id
      }
      recoveryFabricName = azapi_resource.site_recovery_fabric_secondary.name
      recoveryNetworkId  = azapi_resource.virtual_network_target.id
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_replicated_vm" {
  for_each = local.source_vms

  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-10-01"
  name      = azapi_resource.virtual_machine_source[each.key].name
  parent_id = azapi_resource.site_recovery_protection_container_primary.id

  body = {
    properties = {
      policyId = azapi_resource.site_recovery_replication_policy.id
      providerSpecificDetails = {
        fabricObjectId          = azapi_resource.virtual_machine_source[each.key].id
        instanceType            = "A2A"
        recoveryAzureNetworkId  = azapi_resource.virtual_network_target.id
        recoveryContainerId     = azapi_resource.site_recovery_protection_container_secondary.id
        recoveryResourceGroupId = azapi_resource.resource_group_target.id
        recoverySubnetName      = azapi_resource.subnet_target.name
        vmManagedDisks = [
          {
            diskId                              = azapi_resource.virtual_machine_source[each.key].output.properties.storageProfile.osDisk.managedDisk.id
            primaryStagingAzureStorageAccountId = azapi_resource.storage_account_staging.id
            recoveryReplicaDiskAccountType      = "Premium_LRS"
            recoveryResourceGroupId             = azapi_resource.resource_group_target.id
            recoveryTargetDiskAccountType       = "Premium_LRS"
          },
        ]
      }
    }
  }

  response_export_values = ["*"]

  timeouts {
    create = var.site_recovery_replication_timeouts.create
    delete = var.site_recovery_replication_timeouts.delete
    read   = var.site_recovery_replication_timeouts.read
    update = var.site_recovery_replication_timeouts.update
  }

  depends_on = [
    azapi_resource.site_recovery_network_mapping,
    azapi_resource.site_recovery_protection_container_mapping,
  ]
}

resource "azapi_update_resource" "site_recovery_replicated_vm_configuration" {
  for_each = local.source_vms

  type        = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-10-01"
  resource_id = azapi_resource.site_recovery_replicated_vm[each.key].id

  body = {
    properties = {
      providerSpecificDetails = {
        instanceType = "A2A"
      }
      recoveryAzureVMName            = "vm-target-${each.key}-${random_integer.region_seed.result}"
      recoveryAzureVMSize            = var.target_vm_size
      selectedRecoveryAzureNetworkId = azapi_resource.virtual_network_target.id
      selectedTfoAzureNetworkId      = azapi_resource.virtual_network_target.id
    }
  }

  response_export_values = ["*"]

  timeouts {
    create = var.site_recovery_replication_timeouts.create
    delete = var.site_recovery_replication_timeouts.delete
    read   = var.site_recovery_replication_timeouts.read
    update = var.site_recovery_replication_timeouts.update
  }
}
