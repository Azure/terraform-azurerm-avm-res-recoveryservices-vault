
resource "azurerm_backup_policy_vm" "this" {
  name                           = var.vm_backup_policy.name                                                                                                                                                   # var.name
  recovery_vault_name            = var.recovery_vault_name                                                                                                                                                     # var.recovery_vault_name
  resource_group_name            = var.resource_group_name                                                                                                                                                     # var.resource_group_name
  instant_restore_retention_days = var.vm_backup_policy.instant_restore_retention_days != null ? var.vm_backup_policy.policy_type == "Weekly" ? 5 : var.vm_backup_policy.instant_restore_retention_days : null # var.instant_restore_retention_days
  policy_type                    = var.vm_backup_policy.policy_type                                                                                                                                            # var.policy_type
  timezone                       = var.vm_backup_policy.timezone                                                                                                                                               # var.timezone

  backup {
    frequency     = var.vm_backup_policy.frequency != null ? regex("^Hourly|Daily|Weekly$", var.vm_backup_policy.frequency) : null
    time          = var.vm_backup_policy["backup"].time != null ? var.vm_backup_policy["backup"].time : null
    hour_duration = var.vm_backup_policy.frequency == "Hourly" && var.vm_backup_policy["backup"].hour_duration != null ? regex("/0[1-2]|1[0-2]-0[4-9]|1[1-9]|2[0-4]|3[0-1]|[1-2[4-8]/gm", var.vm_backup_policy["backup"].hour_duration) : null
    hour_interval = var.vm_backup_policy.frequency == "Hourly" && var.vm_backup_policy["backup"].hour_interval != null ? regex("^4|6|8|12$", var.vm_backup_policy["backup"].hour_interval) : null
    weekdays      = var.vm_backup_policy.frequency == "Weekly" && length(var.vm_backup_policy["backup"].weekdays) != null ? var.vm_backup_policy["backup"].weekdays : null
  }
  dynamic "instant_restore_resource_group" {
    for_each = length(var.vm_backup_policy.instant_restore_resource_group) > 0 ? var.vm_backup_policy.instant_restore_resource_group : {}

    content {
      prefix = instant_restore_resource_group.value["prefix"] != null ? instant_restore_resource_group.value["prefix"] : "prefix-"
      suffix = instant_restore_resource_group.value["prefix"] != null && instant_restore_resource_group.value["suffix"] != null ? instant_restore_resource_group.value["suffix"] : null
    }
  }
  dynamic "retention_daily" {
    for_each = var.vm_backup_policy.frequency != "Weekly" ? { this = var.vm_backup_policy["retention_daily"] } : {}

    content {
      count = var.vm_backup_policy.frequency != "Weekly" ? var.vm_backup_policy["retention_daily"] : null
    }
  }
  dynamic "retention_monthly" {
    for_each = var.vm_backup_policy["retention_monthly"].count > 0 ? { this = var.vm_backup_policy["retention_monthly"] } : {}

    content {
      count             = var.vm_backup_policy["retention_monthly"].count != 0 ? regex("^[1-9][0-9]{0,3}$", var.vm_backup_policy["retention_monthly"].count) : null
      days              = var.vm_backup_policy["retention_monthly"].count != 0 && var.vm_backup_policy.frequency != "Weekly" ? var.vm_backup_policy["retention_monthly"].days : null
      include_last_days = var.vm_backup_policy["retention_monthly"].count != 0 && var.vm_backup_policy.frequency != "Weekly" ? var.vm_backup_policy["retention_monthly"].include_last_days != null ? var.vm_backup_policy["retention_monthly"].include_last_days : null : null
      weekdays          = var.vm_backup_policy["retention_monthly"].count != 0 && var.vm_backup_policy.frequency == "Weekly" ? length(var.vm_backup_policy["retention_monthly"].weekdays) != 0 ? var.vm_backup_policy["retention_monthly"].weekdays : null : null
      weeks             = var.vm_backup_policy["retention_monthly"].count != 0 && var.vm_backup_policy.frequency == "Weekly" ? length(var.vm_backup_policy["retention_monthly"].weeks) != 0 ? var.vm_backup_policy["retention_monthly"].weeks : null : null
    }
  }
  dynamic "retention_weekly" {
    for_each = var.vm_backup_policy["retention_weekly"].count > 0 && length(var.vm_backup_policy["retention_weekly"].weekdays) > 0 ? { this = var.vm_backup_policy["retention_weekly"] } : {}

    content {
      count    = var.vm_backup_policy.frequency == "Weekly" || var.vm_backup_policy["retention_weekly"].count != 0 ? regex("^[1-9][0-9]{0,3}$", var.vm_backup_policy["retention_weekly"].count) : null # 20
      weekdays = var.vm_backup_policy["retention_weekly"].count != 0 && length(var.vm_backup_policy["retention_weekly"].weekdays) > 0 ? var.vm_backup_policy["retention_weekly"].weekdays : null
    }
  }
  dynamic "retention_yearly" {
    for_each = var.vm_backup_policy["retention_yearly"].count > 0 ? { this = var.vm_backup_policy["retention_yearly"] } : {}

    content {
      count             = var.vm_backup_policy["retention_yearly"].count != 0 && var.vm_backup_policy["retention_yearly"].count != 0 ? regex("^[1-9][0-9]{0,3}$", var.vm_backup_policy["retention_yearly"].count) : null
      months            = var.vm_backup_policy["retention_yearly"].count != 0 && (var.vm_backup_policy["retention_yearly"].count != 0 && length(var.vm_backup_policy["retention_yearly"].months) > 0) ? var.vm_backup_policy["retention_yearly"].months : []                # var.vm_backup_policy["retention_yearly"].months # 
      days              = var.vm_backup_policy["retention_yearly"].count != 0 && var.vm_backup_policy.frequency != "Weekly" ? var.vm_backup_policy["retention_yearly"].days : null                                                                                          # (Optional) The days of the month to retain backups of. Must be between 1 and 31.'
      include_last_days = var.vm_backup_policy["retention_yearly"].count != 0 && var.vm_backup_policy.frequency != "Weekly" ? var.vm_backup_policy["retention_yearly"].include_last_days != null ? var.vm_backup_policy["retention_yearly"].include_last_days : null : null # (Optional) Including the last day of the month, default to false.
      weekdays          = var.vm_backup_policy["retention_yearly"].count != 0 && var.vm_backup_policy.frequency == "Weekly" ? length(var.vm_backup_policy["retention_yearly"].weekdays) != 0 ? var.vm_backup_policy["retention_yearly"].weekdays : null : null              #  (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.
      weeks             = var.vm_backup_policy["retention_yearly"].count != 0 && var.vm_backup_policy.frequency == "Weekly" ? length(var.vm_backup_policy["retention_yearly"].weeks) != 0 ? var.vm_backup_policy["retention_yearly"].weeks : null : null                    #  (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
    }
  }
}
