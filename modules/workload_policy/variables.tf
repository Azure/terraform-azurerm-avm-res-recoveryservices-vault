variable "recovery_vault_name" {
  type        = string
  description = "recovery_vault_name: specify a recovery_vault_name for the Azure Recovery Services Vault. Upper/Lower case letters, numbers and hyphens. number of characters 2-50"

  validation {

    error_message = "Naming error: follow this constrains. Upper/Lower case letters, numbers and hyphens. number of characters 2-50"

    condition = can(regex("^[a-zA-Z0-9-]{2,50}$", var.recovery_vault_name))

  }
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "workload_backup_policy" {
  type = object({
    name          = string
    workload_type = string
    settings = object({
      time_zone           = string
      compression_enabled = bool
    })

    backup_frequency = string
    protection_policy = map(object({
      policy_type           = string # description = "(required) Specify policy type. Full, Differential, Logs"
      retention_daily_count = number
      retention_weekly = optional(object({
        count    = optional(number, null)
        weekdays = optional(set(string), null)
      }), null)
      # retention_daily = optional(number, null) # (Required) The count that is used to count retention duration with duration type Days. Possible values are between 7 and 35.
      backup = optional(object({
        time                 = optional(string)
        frequency_in_minutes = optional(number)
        weekdays             = optional(set(string))
      }), null)

      retention_monthly = optional(object({
        count             = optional(number, null)
        weekdays          = optional(set(string), null)
        weeks             = optional(set(string), null)
        monthdays         = optional(set(number), null)
        include_last_days = optional(bool, false)
      }), null)

      retention_yearly = optional(object({
        count             = optional(number, null)
        months            = optional(set(string), null)
        weekdays          = optional(set(string), null)
        weeks             = optional(set(string), null)
        monthdays         = optional(set(number), null)
        include_last_days = optional(bool, false)
      }), null)

    }))
  })
  default     = null
  description = "(Required)"
}

variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_backup_policies = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource managed by this submodule. Paths use dot notation, for example `properties.settings`.
List indices are not supported; ignore the whole list property instead.
This argument is provider-private, so changes take effect only after apply, and ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_policies` - Body-relative paths ignored on the `Microsoft.RecoveryServices/vaults/backupPolicies` resource.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_backup_policies = optional(string, "Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this submodule.

- `recoveryservices_vaults_backup_policies` - Resource type and API version for the workload backup policy.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ReferencedResourceNotProvisioned"])
    interval_seconds     = optional(number, 10)
    max_interval_seconds = optional(number, 180)
    multiplier           = optional(number, 1.5)
    randomization_factor = optional(number, 0.5)
  })
  default     = {}
  description = <<DESCRIPTION
Retry configuration applied to every AzAPI resource managed by this submodule.

- `error_message_regex` - A list of regular expressions matched against the returned error message. A retry is only attempted when one of the expressions matches.
- `interval_seconds` - The initial interval, in seconds, between retries.
- `max_interval_seconds` - The maximum interval, in seconds, between retries.
- `multiplier` - The factor by which the retry interval increases after each attempt.
- `randomization_factor` - The randomization factor applied to the retry interval. Set to `0` to disable jitter.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = {}
  description = <<DESCRIPTION
Timeouts applied to every AzAPI resource managed by this submodule. Each value is a Go duration string, for example `30m`. A `null` value uses the provider default.

- `create` - The timeout for creating the resource.
- `delete` - The timeout for deleting the resource.
- `read` - The timeout for reading the resource.
- `update` - The timeout for updating the resource.
DESCRIPTION
  nullable    = false
}
