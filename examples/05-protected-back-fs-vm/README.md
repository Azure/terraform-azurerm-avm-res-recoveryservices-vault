<!-- BEGIN_TF_DOCS -->
# Default example

* This deploys the module with site recovery resources.

* fabric and containers
* replication policy
* fabric mapping
* network mapping
* fixes

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

```hcl

data "azurerm_subscription" "this" {}
# This ensures we have unique CAF compliant names for our resources.
# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.test_regions) - 1
  min = 0
}
# This allow use to randomize the name of resources
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}
# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

resource "azurerm_resource_group" "this" {
  location = "westus3"              #local.test_regions[random_integer.region_index.result]
  name     = "rg-westus3-vault-005" #module.naming.resource_group.name_unique
}
resource "azurerm_resource_group" "primary_wus1" {
  location = "westus"
  name     = "rg-vm-westus-primary-005"
}
resource "azurerm_resource_group" "primary_wus2" {
  location = "westus2"
  name     = "rg-vm-westus2-primary-005"
}
resource "azurerm_resource_group" "primary_wus3" {
  location = "westus3"
  name     = "rg-vm-westus3-primary-005"
}
resource "azurerm_resource_group" "secondary_eus" {
  location = "eastus"
  name     = "rg-vm-secondary_eus-005"
}
resource "azurerm_resource_group" "secondary_eus2" {
  location = "eastus2"
  name     = "rg-vm-secondary_eus2-005"
}
resource "azurerm_resource_group" "secondary_cus" {
  location = "centralus"
  name     = "rg-vm-secondary_cus-005"
}
# output "network" {
#   value = "${data.azurerm_subscription.This.id}/resourceGroups/${azurerm_resource_group.primary_wus1.name}/providers/Microsoft.Network/virtualNetworks/vnet-westus"
# }
locals {
  test_regions = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-005"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.5.2" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "7.1.1"

  azure_region = "westus3"
}
# must be located in the same region as the VM to be backed up
resource "azurerm_storage_account" "primary_wus1" {
  account_replication_type = "GRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.primary_wus1.location
  name                     = "srv${azurerm_resource_group.primary_wus1.location}005"
  resource_group_name      = azurerm_resource_group.primary_wus1.name
}

resource "azurerm_storage_account" "primary_wus2" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.primary_wus2.location
  name                     = "srv${azurerm_resource_group.primary_wus2.location}555"
  resource_group_name      = azurerm_resource_group.primary_wus2.name
}
resource "azurerm_storage_account" "primary_wus3" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.primary_wus3.location
  name                     = "srv${azurerm_resource_group.primary_wus3.location}555"
  resource_group_name      = azurerm_resource_group.primary_wus3.name
}
resource "azurerm_storage_account" "sa" {
  account_replication_type = "GRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.primary_wus3.location
  name                     = "fsbk${azurerm_resource_group.primary_wus3.location}555"
  resource_group_name      = azurerm_resource_group.primary_wus3.name
}

resource "azurerm_storage_share" "this" {
  name               = "share1"
  quota              = 50
  storage_account_id = azurerm_storage_account.sa.id
}
resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uami-${azurerm_resource_group.this.location}-005"
  resource_group_name = azurerm_resource_group.this.name
}

module "recovery_services_vault" {

  source = "../../"

  name                                           = local.vault_name #"srv-test-vault-005"
  location                                       = azurerm_resource_group.this.location
  resource_group_name                            = azurerm_resource_group.this.name
  cross_region_restore_enabled                   = false
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  public_network_access_enabled                  = true
  storage_mode_type                              = "GeoRedundant"
  sku                                            = "RS0"
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id, ]
  }

  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }

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
  backup_protected_file_share = {
    protect-share-s1 = {
      source_storage_account_id = "${data.azurerm_subscription.this.id}/resourceGroups/${azurerm_resource_group.primary_wus3.name}/providers/Microsoft.Storage/storageAccounts/fsbk${azurerm_resource_group.primary_wus3.location}005"
      #"${data.azurerm_subscription.this.id}/resourceGroups/${azurerm_resource_group.primary_wus3.name}/providers/Microsoft.Storage/storageAccounts/fsbk${azurerm_resource_group.primary_wus3.location}005"
      source_file_share_name        = azurerm_storage_share.this.name
      backup_file_share_policy_name = "pol-rsv-fileshare-vault-005"
      sleep_timer                   = "30s"
    }
  }
  backup_protected_vm = {
    vm-03 = {
      vm_backup_policy_name = "EnhancedPolicy"
      source_vm_id          = "${data.azurerm_subscription.this.id}/resourceGroups/${azurerm_resource_group.primary_wus3.name}/providers/Microsoft.Compute/virtualMachines/vm-${azurerm_resource_group.primary_wus3.location}-005"
      # azurerm_windows_virtual_machine.vm_wus3.id # nes/vm"
    }

  }

  depends_on = [azurerm_storage_account.sa, azurerm_windows_virtual_machine.vm_wus3]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9.2)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.107.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_managed_disk.vm_wus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) (resource)
- [azurerm_network_interface.vm_wus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_resource_group.primary_wus1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.primary_wus2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.primary_wus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.secondary_cus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.secondary_eus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.secondary_eus2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_storage_account.primary_wus1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_account.primary_wus2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_account.primary_wus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_account.sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_share.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) (resource)
- [azurerm_subnet.centralus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.eastus1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.eastus2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.westus1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.westus2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.westus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_machine_data_disk_attachment.vm_wus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) (resource)
- [azurerm_virtual_network.centralus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network.eastus1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network.eastus2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network.westus1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network.westus2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_virtual_network.westus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_windows_virtual_machine.vm_wus3](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azurerm_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_rsv"></a> [rsv](#output\_rsv)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_azure_region"></a> [azure\_region](#module\_azure\_region)

Source: claranet/regions/azurerm

Version: 7.1.1

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.0

### <a name="module_recovery_services_vault"></a> [recovery\_services\_vault](#module\_recovery\_services\_vault)

Source: ../../

Version:

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: 0.5.2

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->