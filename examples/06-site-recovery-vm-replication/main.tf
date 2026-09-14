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
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  special          = true
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
  location               = "westus2"
  name                   = "rg-site-recovery-${random_integer.region_seed.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2022-09-01"
  body                   = {}
  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_target" {
  location               = "westcentralus"
  name                   = "rg-site-recovery-target-${random_integer.region_seed.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2022-09-01"
  body                   = {}
  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_source" {
  location  = azapi_resource.resource_group_source.location
  name      = "vnet-source-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
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
  location  = azapi_resource.resource_group_target.location
  name      = "vnet-target-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_target.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
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
  name      = "snet-source"
  parent_id = azapi_resource.virtual_network_source.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.10.1.0/24"
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_target" {
  name      = "snet-target"
  parent_id = azapi_resource.virtual_network_target.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.20.1.0/24"
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "network_interface_source" {
  for_each = local.source_vms

  location  = azapi_resource.resource_group_source.location
  name      = "nic-${each.key}-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  type      = "Microsoft.Network/networkInterfaces@2024-05-01"
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

  location  = azapi_resource.resource_group_source.location
  name      = "disk-source-${each.value.vm_key}-${each.value.disk_key}-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  type      = "Microsoft.Compute/disks@2024-03-02"
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

  location  = azapi_resource.resource_group_source.location
  name      = "vm-source-${each.key}-${random_integer.region_seed.result}"
  parent_id = azapi_resource.resource_group_source.id
  type      = "Microsoft.Compute/virtualMachines@2024-07-01"
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
  response_export_values = [
    "properties.storageProfile.osDisk.managedDisk.id",
  ]
  sensitive_body = {
    properties = {
      osProfile = {
        adminPassword = random_password.vm_admin.result
      }
    }
  }
}

resource "azapi_resource" "storage_account_staging" {
  location  = azapi_resource.resource_group_source.location
  name      = "stasr${random_integer.region_seed.result}${random_string.storage_suffix.result}"
  parent_id = azapi_resource.resource_group_source.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
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

  location                                       = azapi_resource.resource_group_target.location
  name                                           = local.primary_vault_name
  resource_group_name                            = azapi_resource.resource_group_target.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
  managed_identities = {
    system_assigned = true
  }
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
  name      = random_uuid.storage_account_contributor_assignment.result
  parent_id = azapi_resource.storage_account_staging.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
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
  name      = random_uuid.storage_blob_data_contributor_assignment.result
  parent_id = azapi_resource.storage_account_staging.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
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
  name      = random_uuid.storage_queue_data_contributor_assignment.result
  parent_id = azapi_resource.storage_account_staging.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
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
  name      = "fabric-primary-${random_integer.region_seed.result}"
  parent_id = module.recovery_services_vault_primary.resource_id
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics@2024-10-01"
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

resource "time_sleep" "wait_for_site_recovery_fabric" {
  create_duration = "2m"

  depends_on = [azapi_resource.site_recovery_fabric_primary]
}

data "azapi_resource_list" "site_recovery_fabrics" {
  parent_id              = module.recovery_services_vault_primary.resource_id
  type                   = "Microsoft.RecoveryServices/vaults/replicationFabrics@2024-10-01"
  response_export_values = ["value"]

  depends_on = [time_sleep.wait_for_site_recovery_fabric]
}

locals {
  site_recovery_fabric_secondary = one([
    for fabric in data.azapi_resource_list.site_recovery_fabrics.output.value : fabric
    if fabric.properties.customDetails.location == azapi_resource.resource_group_target.location
  ])
}

resource "azapi_resource" "site_recovery_protection_container_primary" {
  name      = "pc-primary-${random_integer.region_seed.result}"
  parent_id = azapi_resource.site_recovery_fabric_primary.id
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers@2024-10-01"
  body = {
    properties = {}
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_protection_container_secondary" {
  name      = "pc-secondary-${random_integer.region_seed.result}"
  parent_id = local.site_recovery_fabric_secondary.id
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers@2024-10-01"
  body = {
    properties = {}
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_replication_policy" {
  name      = "replication-policy-${random_integer.region_seed.result}"
  parent_id = module.recovery_services_vault_primary.resource_id
  type      = "Microsoft.RecoveryServices/vaults/replicationPolicies@2024-10-01"
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
  name      = "pcm-primary-secondary-${random_integer.region_seed.result}"
  parent_id = azapi_resource.site_recovery_protection_container_primary.id
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectionContainerMappings@2024-10-01"
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
  name      = "nm-primary-secondary-${random_integer.region_seed.result}"
  parent_id = "${azapi_resource.site_recovery_fabric_primary.id}/replicationNetworks/${azapi_resource.virtual_network_source.name}"
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationNetworks/replicationNetworkMappings@2024-10-01"
  body = {
    properties = {
      fabricSpecificDetails = {
        instanceType     = "AzureToAzure"
        primaryNetworkId = azapi_resource.virtual_network_source.id
      }
      recoveryFabricName = local.site_recovery_fabric_secondary.name
      recoveryNetworkId  = azapi_resource.virtual_network_target.id
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "site_recovery_replicated_vm" {
  for_each = local.source_vms

  name      = azapi_resource.virtual_machine_source[each.key].name
  parent_id = azapi_resource.site_recovery_protection_container_primary.id
  type      = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-10-01"
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

  resource_id = azapi_resource.site_recovery_replicated_vm[each.key].id
  type        = "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-10-01"
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
