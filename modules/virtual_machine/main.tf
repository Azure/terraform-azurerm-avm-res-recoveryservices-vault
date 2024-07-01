/*
# use try() to normalize and validate values for weekly, monthly, yearly retation
locals {

  diff = { for key_index, value in var.backups_config :
    ${key_index}=> value
    if key_index == "differential" && var.vm_policy["backup_frequency"] == "Weekly"
  }
  log = { for key_index, value in var.vm_policy["backup"] :
    ${key_index}=> value
    if key_index == "log"
  }
  full = { for key_index, value in var.vm_policy["backup"] :
    ${key_index}=> value
    if key_index == "full"
  }
  backup = merge(local.full, local.log, local.diff)

}
*/
resource "azurerm_backup_policy_vm" "this" {
  name                           = var.backups_config.name                                                                                                                                               # var.name
  recovery_vault_name            = var.backups_config.recovery_vault_name                                                                                                                                # var.recovery_vault_name
  resource_group_name            = var.backups_config.resource_group_name                                                                                                                                # var.resource_group_name
  instant_restore_retention_days = var.backups_config.instant_restore_retention_days != null ? var.backups_config.policy_type == "Weekly" ? 5 : var.backups_config.instant_restore_retention_days : null # var.instant_restore_retention_days
  policy_type                    = var.backups_config.policy_type                                                                                                                                        # var.policy_type
  timezone                       = var.backups_config.timezone                                                                                                                                           # var.timezone

  backup {
    frequency     = var.backups_config.frequency != null ? regex("^Hourly|Daily|Weekly$", var.backups_config.frequency) : null
    time          = var.backups_config["backup"].time != null ? var.backups_config["backup"].time : null
    hour_duration = var.backups_config.frequency == "Hourly" && var.backups_config["backup"].hour_duration != null ? regex("/0[1-2]|1[0-2]-0[4-9]|1[1-9]|2[0-4]|3[0-1]|[1-2[4-8]/gm", var.backups_config["backup"].hour_duration) : null
    hour_interval = var.backups_config.frequency == "Hourly" && var.backups_config["backup"].hour_interval != null ? regex("^4|6|8|12$", var.backups_config["backup"].hour_interval) : null
    weekdays      = var.backups_config.frequency == "Weekly" && length(var.backups_config["backup"].weekdays) != null ? var.backups_config["backup"].weekdays : null
  }
  dynamic "instant_restore_resource_group" {
    for_each = length(var.backups_config.instant_restore_resource_group) > 0 ? var.backups_config.instant_restore_resource_group : {}
    content {
      prefix = instant_restore_resource_group.value["prefix"] != null ? instant_restore_resource_group.value["prefix"] : "prefix-"
      suffix = instant_restore_resource_group.value["prefix"] != null && instant_restore_resource_group.value["suffix"] != null ? instant_restore_resource_group.value["suffix"] : null
    }
  }
  dynamic "retention_daily" {
    for_each = var.backups_config.frequency != "Weekly" ? { this = var.backups_config["retention_daily"] } : {}
    content {
      count = var.backups_config.frequency != "Weekly" ? var.backups_config["retention_daily"] : null
    }
  }
  retention_monthly {
    count             = var.backups_config["retention_monthly"].count != 0 ? regex("^[1-9999]$", var.backups_config["retention_monthly"].count) : null
    days              = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_monthly"].days : null
    include_last_days = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_monthly"].include_last_days != null ? var.backups_config["retention_monthly"].include_last_days : null : null
    weekdays          = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_monthly"].weekdays) != 0 ? var.backups_config["retention_monthly"].weekdays : null : null
    weeks             = var.backups_config["retention_monthly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_monthly"].weeks) != 0 ? var.backups_config["retention_monthly"].weeks : null : null
  }
  retention_weekly {
    count    = var.backups_config.frequency == "Weekly" || var.backups_config["retention_weekly"].count != 0 ? regex("^[1-9999]$", var.backups_config["retention_weekly"].count) : null # 20
    weekdays = var.backups_config["retention_weekly"].count != 0 && length(var.backups_config["retention_weekly"].weekdays) > 0 ? var.backups_config["retention_weekly"].weekdays : null
  }
  retention_yearly {
    count             = var.backups_config["retention_yearly"].count != 0 && var.backups_config["retention_yearly"].count != 0 ? regex("^[1-9999]$", var.backups_config["retention_yearly"].count) : null
    months            = var.backups_config["retention_yearly"].count != 0 && (var.backups_config["retention_yearly"].count != 0 && length(var.backups_config["retention_yearly"].months) > 0) ? var.backups_config["retention_yearly"].months : []                # var.backups_config["retention_yearly"].months # 
    days              = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_yearly"].days : null                                                                                        # (Optional) The days of the month to retain backups of. Must be between 1 and 31.'
    include_last_days = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency != "Weekly" ? var.backups_config["retention_yearly"].include_last_days != null ? var.backups_config["retention_yearly"].include_last_days : null : null # (Optional) Including the last day of the month, default to false.
    weekdays          = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_yearly"].weekdays) != 0 ? var.backups_config["retention_yearly"].weekdays : null : null              #  (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.
    weeks             = var.backups_config["retention_yearly"].count != 0 && var.backups_config.frequency == "Weekly" ? length(var.backups_config["retention_yearly"].weeks) != 0 ? var.backups_config["retention_yearly"].weeks : null : null                    #  (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
  }
}
