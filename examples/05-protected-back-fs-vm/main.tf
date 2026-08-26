data "azapi_client_config" "current" {}

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

resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-westus3-vault-005"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "westus3"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_primary_wus1" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-vm-westus-primary-005"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "westus"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_primary_wus2" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-vm-westus2-primary-005"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "westus2"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_primary_wus3" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-vm-westus3-primary-005"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "westus3"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_secondary_eus" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-vm-secondary_eus-005"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "eastus"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_secondary_eus2" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-vm-secondary_eus2-005"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "eastus2"

  body = {}

  response_export_values = ["*"]
}

resource "azapi_resource" "resource_group_secondary_cus" {
  type      = "Microsoft.Resources/resourceGroups@2022-09-01"
  name      = "rg-vm-secondary_cus-005"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "centralus"

  body = {}

  response_export_values = ["*"]
}
locals {
  test_regions = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-005"
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "8.0.6"

  azure_region = "westus3"
}
# Must be located in the same region as the VM to be backed up.
resource "azapi_resource" "storage_account_primary_wus1" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = "srv${azapi_resource.resource_group_primary_wus1.location}005"
  parent_id = azapi_resource.resource_group_primary_wus1.id
  location  = azapi_resource.resource_group_primary_wus1.location

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_GRS"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "storage_account_primary_wus2" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = "srv${azapi_resource.resource_group_primary_wus2.location}555"
  parent_id = azapi_resource.resource_group_primary_wus2.id
  location  = azapi_resource.resource_group_primary_wus2.location

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_ZRS"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "storage_account_primary_wus3" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = "srv${azapi_resource.resource_group_primary_wus3.location}555"
  parent_id = azapi_resource.resource_group_primary_wus3.id
  location  = azapi_resource.resource_group_primary_wus3.location

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_ZRS"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "storage_account_file_share" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = "fsbk${azapi_resource.resource_group_primary_wus3.location}555"
  parent_id = azapi_resource.resource_group_primary_wus3.id
  location  = azapi_resource.resource_group_primary_wus3.location

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_GRS"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "storage_share" {
  type      = "Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01"
  name      = "share1"
  parent_id = "${azapi_resource.storage_account_file_share.id}/fileServices/default"

  body = {
    properties = {
      shareQuota = 50
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "user_assigned_identity" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  name      = "uami-${azapi_resource.resource_group.location}-005"
  parent_id = azapi_resource.resource_group.id
  location  = azapi_resource.resource_group.location

  body = {}

  response_export_values = ["*"]
}

resource "random_password" "vm_admin" {
  length           = 20
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

module "recovery_services_vault" {
  source = "../../"

  location                                       = azapi_resource.resource_group.location
  name                                           = local.vault_name #"srv-test-vault-005"
  resource_group_name                            = azapi_resource.resource_group.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  backup_protected_file_share = {
    protect-share-s1 = {
      source_storage_account_id     = azapi_resource.storage_account_file_share.id
      source_file_share_name        = azapi_resource.storage_share.name
      backup_file_share_policy_name = "pol-rsv-fileshare-vault-005"
      sleep_timer                   = "30s"
    }
  }
  backup_protected_vm = {
    vm-03 = {
      vm_backup_policy_name = "EnhancedPolicy"
      source_vm_id          = azapi_resource.virtual_machine_wus3.id
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
    user_assigned_resource_ids = [azapi_resource.user_assigned_identity.id]
  }
  public_network_access_enabled = true
  storage_mode_type             = "GeoRedundant"
  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }

  depends_on = [azapi_resource.storage_account_file_share, azapi_resource.virtual_machine_wus3]
}