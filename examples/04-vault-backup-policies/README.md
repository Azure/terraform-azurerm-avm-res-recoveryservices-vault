<!-- BEGIN_TF_DOCS -->
# Default example

* This deploys the module with backup custom policies file share, virtual machine, workload

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

```hcl


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
  location = local.test_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_resource_group" "primary" {
  location = "westus3"
  name     = "${module.naming.resource_group.name_unique}-wus3"
}
resource "azurerm_resource_group" "secondary" {
  location = "Central US"
  name     = "${module.naming.resource_group.name_unique}-cus"
}
locals {
  test_regions = ["eastus", "eastus2", "westus2"]
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-001"
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
resource "azurerm_user_assigned_identity" "this_identity" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}


module "recovery_services_vault" {
  source = "../../"

  name                                           = local.vault_name
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
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this_identity.id]
  }

  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }
  workload_backup_policy = {
    "pol-rsv-SAPh-vault-002" = {
      name          = "pol-rsv-SAPh-vault-01"
      workload_type = "SAPHanaDatabase"
      settings = {
        time_zone           = "Pacific Standard Time"
        compression_enabled = false
      }
      backup_frequency = "Weekly" # Daily or Weekly
      protection_policy = {
        log = {
          policy_type           = "Log"
          retention_daily_count = 15
          backup = {
            frequency_in_minutes = 15
            time                 = "22:00"
            weekdays             = ["Saturday"]
          }
        }
        full = {
          policy_type = "Full"
          backup = {
            time     = "22:00"
            weekdays = ["Saturday"]
          }
          retention_daily_count = 15
          retention_weekly = {
            count    = 10
            weekdays = ["Saturday"]
          }
          retention_monthly = {
            count     = 10
            weekdays  = ["Saturday", ]
            weeks     = ["First", "Third"]
            monthdays = [3, 10, 20]
          }
          retention_yearly = {
            count     = 10
            months    = ["January", "June", "October", "March"]
            weekdays  = ["Saturday", ]
            weeks     = ["First", "Second", "Third"]
            monthdays = [3, 10, 20]
          }

        }
        differential = {
          policy_type           = "Differential"
          retention_daily_count = 15
          backup = {
            time     = "22:00"
            weekdays = ["Wednesday", "Friday"]
          }
        }

      }
    }
  }
  vm_backup_policy = {
    pol-rsv-vm-vault-001 = {
      name                           = "pol-rsv-vm-vault-001"
      timezone                       = "Pacific Standard Time"
      instant_restore_retention_days = 5
      policy_type                    = "V2"
      frequency                      = "Weekly" # (Required) Sets the backup frequency. Possible values are Hourly, Daily and Weekly
      instant_restore_resource_group = {
        ps = { prefix = "prefix-"
          suffix = null

        }
      }
      backup = {
        time          = "22:00"
        hour_interval = 6
        hour_duration = 12
        weekdays      = ["Tuesday", "Saturday"]
      }
      retention_daily = 7 # 7-9999
      retention_weekly = {
        count    = 7
        weekdays = ["Tuesday", "Saturday"]
      }
      retention_monthly = {
        count             = 5
        weekdays          = ["Tuesday", "Saturday"]
        weeks             = ["First", "Third"]
        days              = [3, 10, 20]
        include_last_days = false
      }
      retention_yearly = {
        count             = 5
        months            = ["January", "June"]
        weekdays          = ["Tuesday", "Saturday"]
        weeks             = ["First", "Third"]
        days              = [3, 10, 20]
        include_last_days = false
      }
    }
  }
  file_share_backup_policy = {
    pol-rsv-fileshare-vault-001 = {
      name     = "pol-rsv-fileshare-vault-001"
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

}

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.107.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.secondary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_user_assigned_identity.this_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

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

### <a name="module_this"></a> [this](#module\_this)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.2.6

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->