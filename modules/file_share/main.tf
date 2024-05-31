/*
# use try() to normalize and validate values for weekly, monthly, yearly retation
locals {

  diff = { for key_index, value in var.backups_config :
    "${key_index}" => value
    if key_index == "differential" && var.vm_policy["backup_frequency"] == "Weekly"
  }
  log = { for key_index, value in var.vm_policy["backup"] :
    "${key_index}" => value
    if key_index == "log"
  }
  full = { for key_index, value in var.vm_policy["backup"] :
    "${key_index}" => value
    if key_index == "full"
  }
  backup = merge(local.full, local.log, local.diff)

}
output "output_backup" {
  value = local.backup
}
*/
resource "azurerm_backup_policy_file_share" "this" {
  # for_each = var.backups_config != {} ? var.backups_config : null

  name                = var.backups_config.name # var.name
  resource_group_name = var.backups_config.resource_group_name # var.resource_group_name
  recovery_vault_name = var.backups_config.recovery_vault_name # var.recovery_vault_name

  timezone = var.backups_config.timezone # var.timezone

  backup {
      frequency = var.backups_config.frequency != null ? regex("^Hourly|Daily$", var.backups_config.frequency) : null
      
      time      = var.backups_config["backup"].time != null ? var.backups_config["backup"].time : null

      hourly {
        interval = var.backups_config.frequency == "Hourly" && var.backups_config["backup"]["nourly"].interval != null ? regex("^4|6|8|12$", var.backups_config["backup"]["nourly"].interval) : null

        start_time = var.backups_config.frequency == "Hourly" && var.backups_config["backup"]["nourly"].start_time != null ? regex("/0[1-2]|1[0-2]-0[4-9]|1[1-9]|2[0-4]|3[0-1]|[1-2[4-8]/gm", var.backups_config["backup"]["nourly"].start_time) : null

        window_duration = var.backups_config.frequency == "Weekly" && length(var.backups_config["backup"]["nourly"].window_duration) != null ? var.backups_config["backup"]["nourly"].window_duration : null
        
      }
  }
  
  dynamic "retention_daily" {
    for_each = var.backups_config.frequency != "Weekly" ? {this = var.backups_config["retention_daily"]} : {}
    content {
      count = var.backups_config.frequency != "Weekly" ? regex("^[1-200]$",var.backups_config["retention_daily"]) : null
    }
  }
  retention_weekly {
      count = var.backups_config.frequency == "Weekly" || var.backups_config["retention_weekly"].count != 0 ? regex("^[1-200]$", var.backups_config["retention_weekly"].count) : null # 20

      weekdays = var.backups_config["retention_weekly"].count != 0 && length(var.backups_config["retention_weekly"].weekdays) > 0 ? var.backups_config["retention_weekly"].weekdays : null
  }
  retention_monthly {
      count = var.backups_config["retention_monthly"].count != 0 ? regex("^[1-120]$", var.backups_config["retention_monthly"].count) : null

      weekdays = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_monthly"].weekdays) != 0 ? var.backups_config["retention_monthly"].weekdays : null : null 

      weeks = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_monthly"].weeks) != 0 ? var.backups_config["retention_monthly"].weeks : null : null 

      days = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_monthly"].days : null

      include_last_days = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_monthly"].include_last_days != null ? var.backups_config["retention_monthly"].include_last_days : null : null 
  }
  retention_yearly {
      count = var.backups_config["retention_yearly"].count != 0 && var.backups_config["retention_yearly"].count != 0 ? regex("^[1-10]$", var.backups_config["retention_yearly"].count) : null

      months = var.backups_config["retention_yearly"].count != 0 && (var.backups_config["retention_yearly"].count != 0 && length(var.backups_config["retention_yearly"].months) > 0) ? var.backups_config["retention_yearly"].months : [] # var.backups_config["retention_yearly"].months # 

      weekdays = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_yearly"].weekdays) != 0 ? var.backups_config["retention_yearly"].weekdays : null : null #  (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.

      weeks = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_yearly"].weeks) != 0 ? var.backups_config["retention_yearly"].weeks : null : null #  (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.

      days = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_yearly"].days : null # (Optional) The days of the month to retain backups of. Must be between 1 and 31.'

      include_last_days = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_yearly"].include_last_days != null ? var.backups_config["retention_yearly"].include_last_days : null : null # (Optional) Including the last day of the month, default to false.
      # NOTE: Either weekdays and weeks or days and include_last_days must be specified.

  }

}
