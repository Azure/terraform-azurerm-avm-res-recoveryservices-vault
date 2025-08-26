
# use try() to normalize and validate values for weekly, monthly, yearly retation
# locals {

#   backup = { for key_index, value in var.file_share_backup_policy.backup :
#     "${key_index}" => value
#   if key_index != "hourly" }
#   log = { for key_index, value in var.file_share_backup_policy["retention_weekly"] :
#     "${key_index}" => value
#     # if key_index == "log"
#   }
#   full = { for key_index, value in var.file_share_backup_policy["retention_monthly"] :
#     "${key_index}" => value
#     # if key_index == "full"
#   }
#   # backup = merge(local.full, local.log, local.diff)

# }

resource "azurerm_backup_policy_file_share" "this" {
  name                = var.file_share_backup_policy.name
  recovery_vault_name = var.recovery_vault_name
  resource_group_name = var.resource_group_name
  timezone            = var.file_share_backup_policy.timezone

  backup {
    frequency = var.file_share_backup_policy.frequency != null ? regex("^Hourly|Daily$", var.file_share_backup_policy.frequency) : null
    time      = var.file_share_backup_policy.frequency == "Daily" && var.file_share_backup_policy["backup"].time != null ? var.file_share_backup_policy["backup"].time : null

    dynamic "hourly" {
      for_each = var.file_share_backup_policy.frequency == "Hourly" ? { this = var.file_share_backup_policy.backup.hourly } : {}

      content {
        interval        = hourly.value.interval != null ? hourly.value.interval : null
        start_time      = hourly.value.start_time != null ? hourly.value.start_time : null
        window_duration = hourly.value.window_duration != null ? hourly.value.window_duration : null
      }
    }
  }
  dynamic "retention_daily" {
    for_each = can(regex("^(?:[1-9][0-9]?|1[0-9]{2}|200)$", var.file_share_backup_policy["retention_daily"])) ? { this = var.file_share_backup_policy["retention_daily"] } : {}

    content {
      count = regex("^(?:[1-9][0-9]?|1[0-9]{2}|200)$", var.file_share_backup_policy["retention_daily"])
    }
  }
  dynamic "retention_monthly" {
    for_each = var.file_share_backup_policy["retention_monthly"].count > 0 ? { this = var.file_share_backup_policy["retention_monthly"] } : {}

    content {
      count             = var.file_share_backup_policy["retention_monthly"].count != 0 ? var.file_share_backup_policy["retention_monthly"].count : null
      days              = var.file_share_backup_policy["retention_monthly"].count != 0 && (length(var.file_share_backup_policy["retention_monthly"].weekdays) == 0 || length(var.file_share_backup_policy["retention_monthly"].weekdays) == 0) ? var.file_share_backup_policy["retention_monthly"].days : null
      include_last_days = var.file_share_backup_policy["retention_monthly"].count != 0 && (length(var.file_share_backup_policy["retention_monthly"].weekdays) == 0 || length(var.file_share_backup_policy["retention_monthly"].weekdays) == 0) ? var.file_share_backup_policy["retention_monthly"].include_last_days != null ? var.file_share_backup_policy["retention_monthly"].include_last_days : null : null
      weekdays          = var.file_share_backup_policy["retention_monthly"].count != 0 && (length(var.file_share_backup_policy["retention_monthly"].days) == 0 || var.file_share_backup_policy["retention_monthly"].include_last_days != null) ? length(var.file_share_backup_policy["retention_monthly"].weekdays) != 0 ? var.file_share_backup_policy["retention_monthly"].weekdays : null : null
      weeks             = var.file_share_backup_policy["retention_monthly"].count != 0 && (length(var.file_share_backup_policy["retention_monthly"].days) == 0 || var.file_share_backup_policy["retention_monthly"].include_last_days != null) ? length(var.file_share_backup_policy["retention_monthly"].weeks) != 0 ? var.file_share_backup_policy["retention_monthly"].weeks : null : null
    }
  }
  dynamic "retention_weekly" {
    for_each = var.file_share_backup_policy["retention_weekly"].count > 0 && length(var.file_share_backup_policy["retention_weekly"].weekdays) > 0 ? { this = var.file_share_backup_policy["retention_weekly"] } : {}

    content {
      count    = var.file_share_backup_policy["retention_weekly"].count != 0 ? var.file_share_backup_policy["retention_weekly"].count : null # 20
      weekdays = var.file_share_backup_policy["retention_weekly"].count != 0 && length(var.file_share_backup_policy["retention_weekly"].weekdays) > 0 ? var.file_share_backup_policy["retention_weekly"].weekdays : null
    }
  }
  dynamic "retention_yearly" {
    for_each = var.file_share_backup_policy["retention_yearly"].count > 0 ? { this = var.file_share_backup_policy["retention_yearly"] } : {}

    content {
      count             = var.file_share_backup_policy["retention_yearly"].count != 0 && var.file_share_backup_policy["retention_yearly"].count != 0 ? var.file_share_backup_policy["retention_yearly"].count : null
      months            = var.file_share_backup_policy["retention_yearly"].count != 0 && (var.file_share_backup_policy["retention_yearly"].count != 0 && length(var.file_share_backup_policy["retention_yearly"].months) > 0) ? var.file_share_backup_policy["retention_yearly"].months : []                                                                                                                # var.file_share_backup_policy["retention_yearly"].months #
      days              = var.file_share_backup_policy["retention_yearly"].count != 0 && (length(var.file_share_backup_policy["retention_yearly"].weekdays) == 0 || length(var.file_share_backup_policy["retention_yearly"].weekdays) == 0) ? var.file_share_backup_policy["retention_yearly"].days : null                                                                                                  # (Optional) The days of the month to retain backups of. Must be between 1 and 31.'
      include_last_days = var.file_share_backup_policy["retention_yearly"].count != 0 && (length(var.file_share_backup_policy["retention_yearly"].weekdays) == 0 || length(var.file_share_backup_policy["retention_yearly"].weekdays) == 0) ? var.file_share_backup_policy["retention_yearly"].include_last_days != null ? var.file_share_backup_policy["retention_yearly"].include_last_days : null : null # (Optional) Including the last day of the month, default to false.
      weekdays          = var.file_share_backup_policy["retention_yearly"].count != 0 && (length(var.file_share_backup_policy["retention_yearly"].days) == 0 || var.file_share_backup_policy["retention_yearly"].include_last_days != null) ? length(var.file_share_backup_policy["retention_yearly"].weekdays) != 0 ? var.file_share_backup_policy["retention_yearly"].weekdays : null : null              #  (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.
      weeks             = var.file_share_backup_policy["retention_yearly"].count != 0 && (length(var.file_share_backup_policy["retention_yearly"].days) == 0 || var.file_share_backup_policy["retention_yearly"].include_last_days != null) ? length(var.file_share_backup_policy["retention_yearly"].weeks) != 0 ? var.file_share_backup_policy["retention_yearly"].weeks : null : null                    #  (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
    }
  }
}
