locals {
  backup = merge(local.full, local.log, local.diff)
  diff = var.workload_backup_policy == null ? {} : { for key_index, value in var.workload_backup_policy.protection_policy :
    (key_index) => value
    if key_index == "differential" && var.workload_backup_policy["backup_frequency"] == "Weekly"
  }
  full = var.workload_backup_policy == null ? {} : { for key_index, value in var.workload_backup_policy.protection_policy :
    (key_index) => value
    if key_index == "full"
  }
  log = var.workload_backup_policy == null ? {} : { for key_index, value in var.workload_backup_policy.protection_policy :
    (key_index) => value
    if key_index == "log"
  }
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "this" {
  count = var.workload_backup_policy == null ? 0 : 1

  name      = var.workload_backup_policy.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.recovery_vault_name}"
  type      = "Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01"
  body = {
    properties = {
      backupManagementType = "AzureWorkload"
      workLoadType         = var.workload_backup_policy.workload_type
      settings = {
        timeZone      = var.workload_backup_policy.settings.time_zone
        isCompression = var.workload_backup_policy.settings.compression_enabled
      }
      subProtectionPolicy = concat(
        [for k, v in local.full : {
          policyType = v.policy_type
          schedulePolicy = var.workload_backup_policy["backup_frequency"] == "Weekly" ? {
            schedulePolicyType   = "SimpleSchedulePolicy"
            scheduleRunFrequency = "Weekly"
            scheduleRunTimes     = v.backup != null ? ["1900-01-01T${v.backup.time}:00Z"] : null
            scheduleRunDays      = v.backup != null ? v.backup.weekdays : null
            } : {
            schedulePolicyType   = "SimpleSchedulePolicy"
            scheduleRunFrequency = "Daily"
            scheduleRunTimes     = v.backup != null ? ["1900-01-01T${v.backup.time}:00Z"] : null
            scheduleRunDays      = null
          }
          retentionPolicy = {
            retentionPolicyType = "LongTermRetentionPolicy"
            dailySchedule = var.workload_backup_policy["backup_frequency"] != "Weekly" ? {
              retentionTimes = v.backup != null ? ["1900-01-01T${v.backup.time}:00Z"] : null
              retentionDuration = {
                count        = v.retention_daily_count
                durationType = "Days"
              }
            } : null
            weeklySchedule = var.workload_backup_policy["backup_frequency"] == "Weekly" && v.retention_weekly != null ? {
              daysOfTheWeek  = v.retention_weekly.weekdays
              retentionTimes = v.backup != null ? ["1900-01-01T${v.backup.time}:00Z"] : null
              retentionDuration = {
                count        = v.retention_weekly.count
                durationType = "Weeks"
              }
            } : null
            monthlySchedule = v.retention_monthly != null && v.retention_monthly.count != null ? {
              retentionScheduleFormatType = var.workload_backup_policy["backup_frequency"] == "Daily" ? "Daily" : "Weekly"
              retentionScheduleDaily = var.workload_backup_policy["backup_frequency"] == "Daily" ? {
                daysOfTheMonth = v.retention_monthly.monthdays != null ? [
                  for d in v.retention_monthly.monthdays : { date = d, isLast = false }
                ] : null
              } : null
              retentionScheduleWeekly = var.workload_backup_policy["backup_frequency"] != "Daily" ? {
                daysOfTheWeek   = v.backup != null ? v.backup.weekdays : null
                weeksOfTheMonth = v.retention_monthly.weeks
              } : null
              retentionTimes = v.backup != null ? ["1900-01-01T${v.backup.time}:00Z"] : null
              retentionDuration = {
                count        = v.retention_monthly.count
                durationType = "Months"
              }
            } : null
            yearlySchedule = v.retention_yearly != null && v.retention_yearly.count != null ? {
              retentionScheduleFormatType = var.workload_backup_policy["backup_frequency"] == "Daily" ? "Daily" : "Weekly"
              retentionScheduleDaily = var.workload_backup_policy["backup_frequency"] == "Daily" ? {
                daysOfTheMonth = v.retention_yearly.monthdays != null ? [
                  for d in v.retention_yearly.monthdays : { date = d, isLast = false }
                ] : null
              } : null
              retentionScheduleWeekly = var.workload_backup_policy["backup_frequency"] != "Daily" ? {
                daysOfTheWeek   = v.backup != null ? v.backup.weekdays : null
                weeksOfTheMonth = v.retention_yearly.weeks
              } : null
              monthsOfYear   = v.retention_yearly.months
              retentionTimes = v.backup != null ? ["1900-01-01T${v.backup.time}:00Z"] : null
              retentionDuration = {
                count        = v.retention_yearly.count
                durationType = "Years"
              }
            } : null
          }
        }],
        [for k, v in local.log : {
          policyType = v.policy_type
          schedulePolicy = {
            schedulePolicyType      = "LogSchedulePolicy"
            scheduleFrequencyInMins = v.backup != null ? v.backup.frequency_in_minutes : null
          }
          retentionPolicy = {
            retentionPolicyType = "SimpleRetentionPolicy"
            retentionDuration = {
              count        = v.retention_daily_count
              durationType = "Days"
            }
          }
        }],
        [for k, v in local.diff : {
          policyType = v.policy_type
          schedulePolicy = {
            schedulePolicyType   = "SimpleSchedulePolicy"
            scheduleRunFrequency = var.workload_backup_policy["backup_frequency"]
            scheduleRunTimes     = v.backup != null ? ["1900-01-01T${v.backup.time}:00Z"] : null
            scheduleRunDays      = var.workload_backup_policy["backup_frequency"] == "Weekly" && v.backup != null ? v.backup.weekdays : null
          }
          retentionPolicy = {
            retentionPolicyType = "SimpleRetentionPolicy"
            retentionDuration = {
              count        = v.retention_daily_count
              durationType = "Days"
            }
          }
        }]
      )
    }
  }
  response_export_values = ["*"]
}
