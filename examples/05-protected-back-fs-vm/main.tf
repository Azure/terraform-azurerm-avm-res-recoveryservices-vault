
data "azapi_client_config" "this" {}
# This ensures we have unique CAF compliant names for our resources.
# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.test_regions) - 1
  min = 0
}
# This allows us to randomize the name of resources
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}
# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

resource "azapi_resource" "rg_this" {
  location  = "westus3"              #local.test_regions[random_integer.region_index.result]
  name      = "rg-westus3-vault-005" #module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${local.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}
resource "azapi_resource" "rg_primary_wus1" {
  location  = "westus"
  name      = "rg-vm-westus-primary-005"
  parent_id = "/subscriptions/${local.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}
resource "azapi_resource" "rg_primary_wus2" {
  location  = "westus2"
  name      = "rg-vm-westus2-primary-005"
  parent_id = "/subscriptions/${local.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}
resource "azapi_resource" "rg_primary_wus3" {
  location  = "westus3"
  name      = "rg-vm-westus3-primary-005"
  parent_id = "/subscriptions/${local.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}
resource "azapi_resource" "rg_secondary_eus" {
  location  = "eastus"
  name      = "rg-vm-secondary_eus-005"
  parent_id = "/subscriptions/${local.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}
resource "azapi_resource" "rg_secondary_eus2" {
  location  = "eastus2"
  name      = "rg-vm-secondary_eus2-005"
  parent_id = "/subscriptions/${local.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}
resource "azapi_resource" "rg_secondary_cus" {
  location  = "centralus"
  name      = "rg-vm-secondary_cus-005"
  parent_id = "/subscriptions/${local.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}
# output "network" {
#   value = "${azapi_resource.rg_primary_wus1.id}/providers/Microsoft.Network/virtualNetworks/vnet-westus"
# }
locals {
  subscription_id = data.azapi_client_config.this.subscription_id
  test_regions    = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name      = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-005"
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "8.0.6"

  azure_region = "westus3"
}
# must be located in the same region as the VM to be backed up
resource "azapi_resource" "sa_primary_wus1" {
  location  = azapi_resource.rg_primary_wus1.location
  name      = "srv${azapi_resource.rg_primary_wus1.location}005"
  parent_id = azapi_resource.rg_primary_wus1.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_GRS"
    }
    properties = {}
  }
}

resource "azapi_resource" "sa_primary_wus2" {
  location  = azapi_resource.rg_primary_wus2.location
  name      = "srv${azapi_resource.rg_primary_wus2.location}555"
  parent_id = azapi_resource.rg_primary_wus2.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_ZRS"
    }
    properties = {}
  }
}
resource "azapi_resource" "sa_primary_wus3" {
  location  = azapi_resource.rg_primary_wus3.location
  name      = "srv${azapi_resource.rg_primary_wus3.location}555"
  parent_id = azapi_resource.rg_primary_wus3.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_ZRS"
    }
    properties = {}
  }
}
resource "azapi_resource" "sa" {
  location  = azapi_resource.rg_primary_wus3.location
  name      = "fsbk${azapi_resource.rg_primary_wus3.location}555"
  parent_id = azapi_resource.rg_primary_wus3.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_GRS"
    }
    properties = {}
  }
}

# The file share is a control-plane ARM child resource of the storage account's
# default file service, so it is created with azapi_resource.
resource "azapi_resource" "share_this" {
  name      = "share1"
  parent_id = "${azapi_resource.sa.id}/fileServices/default"
  type      = "Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01"
  body = {
    properties = {
      shareQuota = 50
    }
  }
}
resource "azapi_resource" "uami_this" {
  location  = azapi_resource.rg_this.location
  name      = "uami-${azapi_resource.rg_this.location}-005"
  parent_id = azapi_resource.rg_this.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  body      = {}
}

module "recovery_services_vault" {
  source = "../../"

  location                                       = azapi_resource.rg_this.location
  name                                           = local.vault_name #"srv-test-vault-005"
  resource_group_name                            = azapi_resource.rg_this.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  backup_protected_file_share = {
    protect-share-s1 = {
      source_storage_account_id = "/subscriptions/${local.subscription_id}/resourceGroups/${azapi_resource.rg_primary_wus3.name}/providers/Microsoft.Storage/storageAccounts/fsbk${azapi_resource.rg_primary_wus3.location}005"
      #"/subscriptions/${local.subscription_id}/resourceGroups/${azapi_resource.rg_primary_wus3.name}/providers/Microsoft.Storage/storageAccounts/fsbk${azapi_resource.rg_primary_wus3.location}005"
      source_file_share_name        = azapi_resource.share_this.name
      backup_file_share_policy_name = "pol-rsv-fileshare-vault-005"
      sleep_timer                   = "30s"
    }
  }
  backup_protected_vm = {
    vm-03 = {
      vm_backup_policy_name = "EnhancedPolicy"
      source_vm_id          = "/subscriptions/${local.subscription_id}/resourceGroups/${azapi_resource.rg_primary_wus3.name}/providers/Microsoft.Compute/virtualMachines/vm-${azapi_resource.rg_primary_wus3.location}-005"
      # azapi_resource.vm_wus3.id # nes/vm"
    }

  }
  classic_vmware_replication_enabled = false
  cross_region_restore_enabled       = false
  file_share_backup_policy = {
    fs_obj_key_pol_001 = {
      name     = "pol-rsv-fileshare-vault-005"
      timezone = "Pacific Standard Time"

      frequency = "Daily" # (Required) Sets the backup frequency. Possible values are hourly, Daily

      backup = {
        time = "22:00"
        hourly = {
          interval        = 6
          start_time      = "13:00"
          window_duration = "6"
        }
      }
      retention_daily = 1 # 1-200
      retention_weekly = {
        count    = 7
        weekdays = ["Tuesday", "Saturday"]
      }
      retention_monthly = {
        count = 5
        # weekdays =  ["Tuesday","Saturday"]
        # weeks = ["First","Third"]
        days              = [3, 10, 20]
        include_last_days = false
      }
      retention_yearly = {
        count    = 5
        months   = ["January", "June"]
        weekdays = ["Tuesday", "Saturday"]
        weeks    = ["First", "Third"]
        # days = [3, 10, 20]
        # include_last_days = false
      }
    }
  }
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azapi_resource.uami_this.id, ]
  }
  public_network_access_enabled = true
  storage_mode_type             = "GeoRedundant"
  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }

  depends_on = [azapi_resource.sa, azapi_resource.vm_wus3]
}