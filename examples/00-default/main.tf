

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

resource "azurerm_resource_group" "this" {
  location = local.test_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

locals {
  test_regions = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-001"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.8.2" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "8.0.5"

  azure_region = "westus3"
}

module "recovery_services_vault" {
  source = "../../"

  location                                       = azurerm_resource_group.this.location
  name                                           = local.vault_name #"rsv-test-vault-001"
  resource_group_name                            = azurerm_resource_group.this.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
  public_network_access_enabled                  = true
  storage_mode_type                              = "GeoRedundant"
  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
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
    pol-rsv-fileshare-vault-002 = {
      name                       = "pol-rsv-fileshare-vault-002"
      timezone                   = "Pacific Standard Time"
      frequency                  = "Daily"
      backup_tier                = "vault-standard"
      snapshot_retention_in_days = 5
      backup = {
        time = "22:00"
      }
      retention_daily = 7 # must be greater than snapshot_retention_in_days when backup_tier is vault-standard
      retention_weekly = {
        count    = 7
        weekdays = ["Tuesday", "Saturday"]
      }
      retention_monthly = {
        count    = 5
        weekdays = ["Tuesday", "Saturday"]
        weeks    = ["First", "Third"]
      }
      retention_yearly = {
        count    = 5
        months   = ["January", "June"]
        weekdays = ["Tuesday", "Saturday"]
        weeks    = ["First", "Third"]
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
        ps = {
          prefix = "prefix-"
          suffix = null
        }
      }
      backup = {
        time     = "22:00"
        weekdays = ["Saturday"]
      }
      retention_daily = 7 # 7-9999
      retention_weekly = {
        count    = 7
        weekdays = ["Saturday"]
      }
      retention_monthly = {
        count    = 5
        weekdays = ["Saturday"]
        weeks    = ["First", "Third"]
      }
      retention_yearly = {
        count    = 5
        months   = ["January", "June"]
        weekdays = ["Saturday"]
        weeks    = ["First", "Third"]
      }
    }
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
            count    = 10
            weekdays = ["Saturday"]
            weeks    = ["First", "Third"]
          }
          retention_yearly = {
            count    = 10
            months   = ["January", "June", "October", "March"]
            weekdays = ["Saturday"]
            weeks    = ["First", "Second", "Third"]
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
    "pol-rsv-sql-vault-001" = {
      name          = "pol-rsv-sql-vault-001"
      workload_type = "SQLDataBase"
      settings = {
        time_zone           = "Pacific Standard Time"
        compression_enabled = true
      }
      backup_frequency = "Daily" # Daily or Weekly
      protection_policy = {
        full = {
          policy_type           = "Full"
          retention_daily_count = 7
          backup = {
            time = "22:00"
          }
          retention_weekly = {
            count    = 5
            weekdays = ["Sunday"]
          }
          retention_monthly = {
            count     = 4
            monthdays = [1]
          }
          retention_yearly = {
            count     = 1
            months    = ["January"]
            monthdays = [1]
          }
        }
        log = {
          policy_type           = "Log"
          retention_daily_count = 7
          backup = {
            frequency_in_minutes = 15
            time                 = "22:00"
          }
        }
      }
    }
    "pol-rsv-sql-vault-daily-weekbased-001" = {
      name          = "pol-rsv-sql-vault-daily-weekbased-001"
      workload_type = "SQLDataBase"
      settings = {
        time_zone           = "Pacific Standard Time"
        compression_enabled = true
      }
      backup_frequency = "Daily"
      protection_policy = {
        full = {
          policy_type           = "Full"
          retention_daily_count = 7
          backup = {
            time = "21:00"
          }
          retention_weekly = {
            count    = 8
            weekdays = ["Sunday"]
          }
          retention_monthly = {
            count    = 60
            weekdays = ["Sunday"]
            weeks    = ["First"]
          }
          retention_yearly = {
            count    = 10
            months   = ["January"]
            weekdays = ["Sunday"]
            weeks    = ["First"]
          }
        }
        log = {
          policy_type           = "Log"
          retention_daily_count = 7
          backup = {
            frequency_in_minutes = 15
            time                 = "21:00"
          }
        }
      }
    }
    "pol-rsv-sql-vault-weekly-001" = {
      name          = "pol-rsv-sql-vault-weekly-001"
      workload_type = "SQLDataBase"
      settings = {
        time_zone           = "Pacific Standard Time"
        compression_enabled = true
      }
      backup_frequency = "Weekly"
      protection_policy = {
        full = {
          policy_type           = "Full"
          retention_daily_count = 7
          backup = {
            time     = "02:00"
            weekdays = ["Sunday"]
          }
          retention_weekly = {
            count    = 8
            weekdays = ["Sunday"]
          }
          retention_monthly = {
            count    = 60
            weekdays = ["Sunday"]
            weeks    = ["First"]
          }
          retention_yearly = {
            count    = 10
            months   = ["January"]
            weekdays = ["Sunday"]
            weeks    = ["First"]
          }
        }
        differential = {
          policy_type           = "Differential"
          retention_daily_count = 7
          backup = {
            time     = "03:00"
            weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
          }
        }
        log = {
          policy_type           = "Log"
          retention_daily_count = 7
          backup = {
            frequency_in_minutes = 15
            time                 = "02:00"
          }
        }
      }
    }
  }
}
