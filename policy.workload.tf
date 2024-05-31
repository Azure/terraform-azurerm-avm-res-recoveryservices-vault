
module "recovery_workload_policy" {
  source = "./modules/workload"

  workload_policy = {
    name                = "pol-rsv-SAPh-vault-01"
    resource_group_name = var.resource_group_name
    recovery_vault_name = azurerm_recovery_services_vault.this.name
    workload_type       = "SAPHanaDatabase"
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