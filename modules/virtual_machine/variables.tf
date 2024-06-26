variable "backups_config" {
  type = object({
    name                           = string
    resource_group_name            = string
    recovery_vault_name            = string
    timezone                       = string
    instant_restore_retention_days = optional(number, null)
    instant_restore_resource_group = map(object({
      prefix = optional(string, null)
      suffix = optional(string, null)

    }))
    policy_type = string
    frequency   = string

    retention_daily = optional(number, null)

    backup = object({
      time          = string
      hour_interval = optional(number, null)
      hour_duration = optional(number, null)
      weekdays      = optional(list(string), [])
    })

    retention_weekly = optional(object({
      count    = optional(number, 7)
      weekdays = optional(list(string), [])
    }), {})

    retention_monthly = optional(object({
      count             = optional(number, 0)
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }), {})

    retention_yearly = optional(object({
      count             = optional(number, 0)
      months            = optional(list(string), [])
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }), {})
  })
  default     = null
  description = <<DESCRIPTION
    A map objects for backup and retation options.

    - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
    - `role_assignments` - (Optional) A map of role assignments to create on the 

    - `backup` - (required) backup options.
        - `frequency` - (Required) Sets the backup frequency. Possible values are Hourly, Daily and Weekly.
        - `time` - (required) Specify time in a 24 hour format HH:MM. "22:00"
        - `hour_interval` - (Optional) Interval in hour at which backup is triggered. Possible values are 4, 6, 8 and 12. This is used when frequency is Hourly. 6
        - `hour_duration` -  (Optional) Duration of the backup window in hours. Possible values are between 4 and 24 This is used when frequency is Hourly. 12
        - `weekdays` -  (Optional) The days of the week to perform backups on. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. This is used when frequency is Weekly. ["Tuesday", "Saturday"]
    - `retention_daily` - (Optional)
      - `count` - 
    - `retantion_weekly` -
      - `count` -
      - `weekdays` -
    - `retantion_monthly` -
      - `count` -  # (Required) The number of monthly backups to keep. Must be between 1 and 9999
      - `weekdays` - (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.
      - `weeks` -  # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
      - `days` -  # (Optional) The days of the month to retain backups of. Must be between 1 and 31.
      - `include_last_days` -  # (Optional) Including the last day of the month, default to false.
    - `retantion_yearly` -
      - `months` - # (Required) The months of the year to retain backups of. Must be one of January, February, March, April, May, June, July, August, September, October, November and December.
      - `count` -  # (Required) The number of monthly backups to keep. Must be between 1 and 9999
      - `weekdays` - (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.
      - `weeks` -  # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
      - `days` -  # (Optional) The days of the month to retain backups of. Must be between 1 and 31.
      - `include_last_days` -  # (Optional) Including the last day of the month, default to false.

    example:
      retentions = {
      rest1 = {
        backup = {
          frequency     = "Hourly"
          time          = "22:00"
          hour_interval = 6
          hour_duration = 12
          # weekdays      = ["Tuesday", "Saturday"]
        }
        retention_daily = 7
        retention_weekly = {
          count    = 7
          weekdays = ["Monday", "Wednesday"]

        }
        retention_monthly = {
          count = 5
          # weekdays =  ["Tuesday","Saturday"]
          # weeks = ["First","Third"]
          days = [3, 10, 20]
        }
        retention_yearly = {
          count  = 5
          months = []
          # weekdays =  ["Tuesday","Saturday"]
          # weeks = ["First","Third"]
          days = [3, 10, 20]
        }

        }
      }
    DESCRIPTION
}

variable "instant_restore_resource_group" {
  type = map(object({
    prefix = optional(string, null)
    suffix = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  (optional) Specify restore resource group pefix and/or suffix.
  `prefix` = prefix for the restore resource group name
  `suffix = suffic for the restore resource group name.
  DESCRIPTION
}

variable "instant_restore_retention_days" {
  type        = number
  default     = null # this number can't be higher than retention_daily count
  description = <<DESCRIPTION
  (Optional) Specifies the instant restore retention range in days. Possible values are between 1 and 5 when policy_type is V1, and 1 to 30 when policy_type is V2. 
  instant_restore_retention_days must be set to 5 if the backup frequency is set to Weekly.
  DESCRIPTION
}

variable "policy_type" {
  type        = string
  default     = "V2"
  description = "(required) Specify policy type. V1, V2 (default)"
}

variable "timezone" {
  type        = string
  default     = "Pacific Standard Time"
  description = <<DESCRIPTION
  (required) Specify time zone. default UTC, Pacific Standard Time
  for other times visit: https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/
  DESCRIPTION
}
