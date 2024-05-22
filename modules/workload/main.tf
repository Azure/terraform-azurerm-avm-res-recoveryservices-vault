
locals {

  diff = { for key_index, value in var.workload_policy.protection_policy :
    "${key_index}" => value
    if key_index == "differential" && var.workload_policy["backup_frequency"] == "Weekly"
  }
  log = { for key_index, value in var.workload_policy.protection_policy :
    "${key_index}" => value
    if key_index == "log"
  }
  full = { for key_index, value in var.workload_policy.protection_policy :
    "${key_index}" => value
    if key_index == "full"
  }
  backup = merge(local.full, local.log, local.diff)

}
output "output_protection_policy" {
  value = local.backup
}
resource "azurerm_backup_policy_vm_workload" "this" {
  name                = var.workload_policy.name
  resource_group_name = var.workload_policy.resource_group_name
  recovery_vault_name = var.workload_policy.recovery_vault_name
  workload_type       = var.workload_policy.workload_type
  settings {
    time_zone           = var.workload_policy.settings["time_zone"] # https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/
    compression_enabled = var.workload_policy.settings["compression_enabled"]
  }

  dynamic "protection_policy" {
    for_each = length(local.full) > 0 ? local.full : {}
    content {
      policy_type = protection_policy.value["policy_type"]
      backup {
        frequency            = var.workload_policy["backup_frequency"] != null ? var.workload_policy["backup_frequency"] : null                               #60 #(required) The backup frequency in minutes for the VM Workload Backup Policy. Possible values are 15, 30, 60, 120, 240, 480, 720 and 1440.
        time                 = protection_policy.value["backup"].time != null ? protection_policy.value["backup"].time : null
        weekdays             = var.workload_policy["backup_frequency"] != "Daily" && protection_policy.value["backup"].weekdays != null ? protection_policy.value["backup"].weekdays : null # 
      }

      dynamic "retention_daily" {
        for_each = var.workload_policy["backup_frequency"] != "Weekly" ? { this = protection_policy.value["retention_daily_count"] } : {}
        content {
          count = protection_policy.value["retention_daily_count"]
        }
      }
      dynamic "retention_weekly" {
        for_each = var.workload_policy["backup_frequency"] == "Weekly" ? { this = protection_policy.value["retention_weekly"] } : {}
        content {
          count = retention_weekly.value.count
          weekdays = retention_weekly.value.weekdays
        }
      }
      dynamic "retention_monthly" {
        for_each = protection_policy.value["retention_monthly"] != null ? { this = protection_policy.value["retention_monthly"] } : {}
        content {
          format_type = var.workload_policy["backup_frequency"]

          count = protection_policy.value["retention_monthly"].count != null ? protection_policy.value["retention_monthly"].count : null # (Required) The number of monthly backups to keep. Must be between 1 and 9999

          weekdays = protection_policy.value["retention_monthly"].count != null && length(protection_policy.value["retention_monthly"].weeks) > 0 && length(protection_policy.value["backup"].weekdays) > 0 ? protection_policy.value["backup"].weekdays : [] # (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.

          weeks     = protection_policy.value["retention_monthly"].count != null && var.workload_policy["backup_frequency"] == "Weekly" ? protection_policy.value["retention_monthly"].weeks : null # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
          
          monthdays = var.workload_policy["backup_frequency"] == "Daily" ? protection_policy.value["retention_monthly"].monthdays : []
        }
      }
      dynamic "retention_yearly" {
        for_each = protection_policy.value["retention_yearly"] != null ? { this = protection_policy.value["retention_yearly"] } : {}
        content {
          format_type = var.workload_policy["backup_frequency"]

          count = protection_policy.value["retention_yearly"].count != null ? protection_policy.value["retention_yearly"].count : null # (Required) The number of monthly backups to keep. Must be between 1 and 9999

          weeks = protection_policy.value["retention_yearly"].count != 0 && var.workload_policy["backup_frequency"] == "Weekly" ? protection_policy.value["retention_yearly"].weeks : null # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.

          weekdays = protection_policy.value["retention_yearly"].count != 0 && length(protection_policy.value["retention_yearly"].months) > 0 && length(protection_policy.value["retention_yearly"].weeks) > 0 ? protection_policy.value["backup"].weekdays : null # (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.

          months = (protection_policy.value["retention_yearly"].count != null && length(protection_policy.value["retention_yearly"].months) > 0) ? protection_policy.value["retention_yearly"].months : [] # (Required) The months of the year to retain backups of. Must be one of January, February, March, April, May, June, July, August, September, October, November and December.

          monthdays = var.workload_policy["backup_frequency"] == "Daily" ? protection_policy.value["retention_yearly"].monthdays : []

          # NOTE: Either weekdays and weeks or days and include_last_days must be specified.
        }
      }

    }
  }
  
  # log backup
  dynamic "protection_policy" {
    for_each = length(local.log) > 0 ? local.log : {}
    content{
      policy_type = protection_policy.value["policy_type"]
      backup {
        frequency_in_minutes = protection_policy.value["backup"].frequency_in_minutes != null ? protection_policy.value["backup"].frequency_in_minutes : null #60 #(required) The backup frequency in minutes for the VM Workload Backup Policy. Possible values are 15, 30, 60, 120, 240, 480, 720 and 1440.
      }
      simple_retention {
          count = protection_policy.value["retention_daily_count"] # (Required) The count that is used to count retention duration with duration type Days. Possible values are between 7 and 35.
      }
    }
  }

  # diff backup
  dynamic "protection_policy" {
    for_each = length(local.diff) > 0 ? local.diff : {}
    content {
      policy_type = protection_policy.value["policy_type"]
      backup {
        frequency            = var.workload_policy["backup_frequency"]
        time                 = protection_policy.value["backup"].time
        weekdays             = protection_policy.value["backup"].weekdays
      }
      simple_retention {
        count = protection_policy.value["retention_daily_count"] 
        # (Required) The count that is used to count retention duration with duration type Days. Possible values are between 7 and 35.
      }
    }
  }
  
}