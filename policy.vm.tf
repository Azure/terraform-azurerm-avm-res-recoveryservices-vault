
module "recovery_services_vault_vm_policy" {
  source                         = "./modules/virtual_machine"
  timezone                       = "Pacific Standard Time"
  instant_restore_retention_days = 5
  policy_type                    = "V2"
  instant_restore_resource_group = {
    ps = { prefix = "prefix-"
      suffix = null

    }
  }
  backups_config = {
    name                           = "pol-rsv-vm-vault-001"
    resource_group_name            = var.resource_group_name
    recovery_vault_name            = azurerm_recovery_services_vault.this.name
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