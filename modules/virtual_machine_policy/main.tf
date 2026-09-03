locals {
  api_version = split("@", var.resource_types.recoveryservices_vaults_backup_policies)[1]
  retention_policy = {
    retentionPolicyType = "LongTermRetentionPolicy"
    dailySchedule = var.vm_backup_policy.frequency != "Weekly" && var.vm_backup_policy.retention_daily != null ? {
      retentionTimes = [local.time_formatted]
      retentionDuration = {
        count        = var.vm_backup_policy.retention_daily
        durationType = "Days"
      }
    } : null
    weeklySchedule = var.vm_backup_policy["retention_weekly"].count > 0 && length(var.vm_backup_policy["retention_weekly"].weekdays) > 0 ? {
      daysOfTheWeek  = var.vm_backup_policy["retention_weekly"].weekdays
      retentionTimes = [local.time_formatted]
      retentionDuration = {
        count        = var.vm_backup_policy["retention_weekly"].count
        durationType = "Weeks"
      }
    } : null
    monthlySchedule = var.vm_backup_policy["retention_monthly"].count > 0 ? {
      retentionScheduleFormatType = (length(var.vm_backup_policy["retention_monthly"].days) > 0 || var.vm_backup_policy["retention_monthly"].include_last_days) ? "Daily" : "Weekly"
      retentionScheduleDaily = (length(var.vm_backup_policy["retention_monthly"].days) > 0 || var.vm_backup_policy["retention_monthly"].include_last_days) ? {
        daysOfTheMonth = length(var.vm_backup_policy["retention_monthly"].days) > 0 ? [
          for d in var.vm_backup_policy["retention_monthly"].days : { date = d, isLast = false }
        ] : null
      } : null
      retentionScheduleWeekly = !(length(var.vm_backup_policy["retention_monthly"].days) > 0 || var.vm_backup_policy["retention_monthly"].include_last_days) ? {
        daysOfTheWeek   = var.vm_backup_policy["retention_monthly"].weekdays
        weeksOfTheMonth = var.vm_backup_policy["retention_monthly"].weeks
      } : null
      retentionTimes = [local.time_formatted]
      retentionDuration = {
        count        = var.vm_backup_policy["retention_monthly"].count
        durationType = "Months"
      }
    } : null
    yearlySchedule = var.vm_backup_policy["retention_yearly"].count > 0 ? {
      retentionScheduleFormatType = (length(var.vm_backup_policy["retention_yearly"].days) > 0 || var.vm_backup_policy["retention_yearly"].include_last_days) ? "Daily" : "Weekly"
      retentionScheduleDaily = (length(var.vm_backup_policy["retention_yearly"].days) > 0 || var.vm_backup_policy["retention_yearly"].include_last_days) ? {
        daysOfTheMonth = length(var.vm_backup_policy["retention_yearly"].days) > 0 ? [
          for d in var.vm_backup_policy["retention_yearly"].days : { date = d, isLast = false }
        ] : null
      } : null
      retentionScheduleWeekly = !(length(var.vm_backup_policy["retention_yearly"].days) > 0 || var.vm_backup_policy["retention_yearly"].include_last_days) ? {
        daysOfTheWeek   = var.vm_backup_policy["retention_yearly"].weekdays
        weeksOfTheMonth = var.vm_backup_policy["retention_yearly"].weeks
      } : null
      monthsOfYear   = var.vm_backup_policy["retention_yearly"].months
      retentionTimes = [local.time_formatted]
      retentionDuration = {
        count        = var.vm_backup_policy["retention_yearly"].count
        durationType = "Years"
      }
    } : null
  }
  schedule_policy = jsondecode(var.vm_backup_policy.policy_type == "V2" ? (
    var.vm_backup_policy.frequency == "Hourly" ? jsonencode({
      schedulePolicyType   = "SimpleSchedulePolicyV2"
      scheduleRunFrequency = "Hourly"
      hourlySchedule = {
        interval                = var.vm_backup_policy["backup"].hour_interval
        scheduleWindowStartTime = local.time_formatted
        scheduleWindowDuration  = var.vm_backup_policy["backup"].hour_duration
      }
      }) : var.vm_backup_policy.frequency == "Daily" ? jsonencode({
      schedulePolicyType   = "SimpleSchedulePolicyV2"
      scheduleRunFrequency = "Daily"
      dailySchedule = {
        scheduleRunTimes = [local.time_formatted]
      }
      }) : jsonencode({
      schedulePolicyType   = "SimpleSchedulePolicyV2"
      scheduleRunFrequency = "Weekly"
      weeklySchedule = {
        scheduleRunDays  = var.vm_backup_policy["backup"].weekdays
        scheduleRunTimes = [local.time_formatted]
      }
    })
    ) : (
    var.vm_backup_policy.frequency == "Weekly" ? jsonencode({
      schedulePolicyType   = "SimpleSchedulePolicy"
      scheduleRunFrequency = "Weekly"
      scheduleRunTimes     = [local.time_formatted]
      scheduleRunDays      = var.vm_backup_policy["backup"].weekdays
      }) : jsonencode({
      schedulePolicyType   = "SimpleSchedulePolicy"
      scheduleRunFrequency = "Daily"
      scheduleRunTimes     = [local.time_formatted]
    })
  ))
  time_formatted = "1900-01-01T${var.vm_backup_policy["backup"].time}:00Z"

  base_properties = {
    backupManagementType          = "AzureIaasVM"
    policyType                    = var.vm_backup_policy.policy_type
    timeZone                      = var.vm_backup_policy.timezone
    instantRpRetentionRangeInDays = var.vm_backup_policy.instant_restore_retention_days != null ? (var.vm_backup_policy.policy_type == "Weekly" ? 5 : var.vm_backup_policy.instant_restore_retention_days) : null
    schedulePolicy                = local.schedule_policy
    retentionPolicy               = local.retention_policy
  }

  properties = merge(
    local.base_properties,
    length(var.vm_backup_policy.instant_restore_resource_group) > 0 ? {
      instantRPDetails = {
        azureBackupRGNamePrefix = values(var.vm_backup_policy.instant_restore_resource_group)[0].prefix
        azureBackupRGNameSuffix = values(var.vm_backup_policy.instant_restore_resource_group)[0].suffix
      }
    } : {}
  )
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "this" {
  name      = var.vm_backup_policy.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.recovery_vault_name}"
  type      = var.resource_types.recoveryservices_vaults_backup_policies
  body = {
    properties = local.properties
  }
  ignore_body_changes = length(var.ignore_body_changes.recoveryservices_vaults_backup_policies) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_policies : null
  read_query_parameters = {
    "api-version" = [local.api_version]
  }
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
