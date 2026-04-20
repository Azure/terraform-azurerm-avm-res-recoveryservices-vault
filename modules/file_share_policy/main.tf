locals {
  daily_time_formatted = "1900-01-01T${var.file_share_backup_policy["backup"].time}:00Z"
  hourly_start_time    = var.file_share_backup_policy.frequency == "Hourly" && var.file_share_backup_policy.backup.hourly != null ? "1900-01-01T${var.file_share_backup_policy.backup.hourly.start_time}:00Z" : null
  retention_policy = {
    retentionPolicyType = "LongTermRetentionPolicy"
    dailySchedule = can(regex("^(?:[1-9][0-9]?|1[0-9]{2}|200)$", tostring(var.file_share_backup_policy["retention_daily"]))) ? {
      retentionTimes = [local.retention_time]
      retentionDuration = {
        count        = var.file_share_backup_policy["retention_daily"]
        durationType = "Days"
      }
    } : null
    weeklySchedule = var.file_share_backup_policy["retention_weekly"].count > 0 && length(var.file_share_backup_policy["retention_weekly"].weekdays) > 0 ? {
      daysOfTheWeek  = var.file_share_backup_policy["retention_weekly"].weekdays
      retentionTimes = [local.retention_time]
      retentionDuration = {
        count        = var.file_share_backup_policy["retention_weekly"].count
        durationType = "Weeks"
      }
    } : null
    monthlySchedule = var.file_share_backup_policy["retention_monthly"].count > 0 ? {
      retentionScheduleFormatType = (length(var.file_share_backup_policy["retention_monthly"].days) > 0 || var.file_share_backup_policy["retention_monthly"].include_last_days) ? "Daily" : "Weekly"
      retentionScheduleDaily = (length(var.file_share_backup_policy["retention_monthly"].days) > 0 || var.file_share_backup_policy["retention_monthly"].include_last_days) ? {
        daysOfTheMonth = length(var.file_share_backup_policy["retention_monthly"].days) > 0 ? [
          for d in var.file_share_backup_policy["retention_monthly"].days : { date = d, isLast = false }
        ] : null
      } : null
      retentionScheduleWeekly = !(length(var.file_share_backup_policy["retention_monthly"].days) > 0 || var.file_share_backup_policy["retention_monthly"].include_last_days) ? {
        daysOfTheWeek   = var.file_share_backup_policy["retention_monthly"].weekdays
        weeksOfTheMonth = var.file_share_backup_policy["retention_monthly"].weeks
      } : null
      retentionTimes = [local.retention_time]
      retentionDuration = {
        count        = var.file_share_backup_policy["retention_monthly"].count
        durationType = "Months"
      }
    } : null
    yearlySchedule = var.file_share_backup_policy["retention_yearly"].count > 0 ? {
      retentionScheduleFormatType = (length(var.file_share_backup_policy["retention_yearly"].days) > 0 || var.file_share_backup_policy["retention_yearly"].include_last_days) ? "Daily" : "Weekly"
      retentionScheduleDaily = (length(var.file_share_backup_policy["retention_yearly"].days) > 0 || var.file_share_backup_policy["retention_yearly"].include_last_days) ? {
        daysOfTheMonth = length(var.file_share_backup_policy["retention_yearly"].days) > 0 ? [
          for d in var.file_share_backup_policy["retention_yearly"].days : { date = d, isLast = false }
        ] : null
      } : null
      retentionScheduleWeekly = !(length(var.file_share_backup_policy["retention_yearly"].days) > 0 || var.file_share_backup_policy["retention_yearly"].include_last_days) ? {
        daysOfTheWeek   = var.file_share_backup_policy["retention_yearly"].weekdays
        weeksOfTheMonth = var.file_share_backup_policy["retention_yearly"].weeks
      } : null
      monthsOfYear   = var.file_share_backup_policy["retention_yearly"].months
      retentionTimes = [local.retention_time]
      retentionDuration = {
        count        = var.file_share_backup_policy["retention_yearly"].count
        durationType = "Years"
      }
    } : null
  }
  retention_time = var.file_share_backup_policy.frequency == "Hourly" && local.hourly_start_time != null ? local.hourly_start_time : local.daily_time_formatted
  schedule_policy = var.file_share_backup_policy.frequency == "Hourly" ? {
    schedulePolicyType   = "SimpleSchedulePolicyV2"
    scheduleRunFrequency = "Hourly"
    scheduleRunTimes     = null
    hourlySchedule = var.file_share_backup_policy.backup.hourly != null ? {
      interval                = var.file_share_backup_policy.backup.hourly.interval
      scheduleWindowStartTime = local.hourly_start_time
      scheduleWindowDuration  = var.file_share_backup_policy.backup.hourly.window_duration
    } : null
    } : {
    schedulePolicyType   = "SimpleSchedulePolicy"
    scheduleRunFrequency = "Daily"
    scheduleRunTimes     = [local.daily_time_formatted]
    hourlySchedule       = null
  }
  use_vault_standard = lower(var.file_share_backup_policy.backup_tier) == "vault-standard"
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "this" {
  name      = var.file_share_backup_policy.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.recovery_vault_name}"
  type      = "Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01"
  read_query_parameters = {
    "api-version" = ["2024-10-01"]
  }
  body = {
    properties = {
      backupManagementType = "AzureStorage"
      workLoadType         = "AzureFileShare"
      timeZone             = var.file_share_backup_policy.timezone
      schedulePolicy       = local.schedule_policy
      retentionPolicy      = local.use_vault_standard ? null : local.retention_policy
      vaultRetentionPolicy = local.use_vault_standard ? {
        snapshotRetentionInDays = var.file_share_backup_policy.snapshot_retention_in_days
        vaultRetention          = local.retention_policy
      } : null
    }
  }
  response_export_values = ["*"]
}
