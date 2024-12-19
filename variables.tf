variable "cross_region_restore_enabled" {
  type        = bool
  description = "(optional) Specify Cross Region Restore. true, false (default). var.storage_mode_type must GeoRedundant when setting to true"
  default = true
}

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
  nullable    = false
}

# This is required for most resource modules
variable "name" {
  type        = string
  description = "Name: specify a name for the Azure Recovery Services Vault. Upper/Lower case letters, numbers and hyphens. number of characters 2-50"

  validation {

    error_message = "Naming error: follow this constrains. Upper/Lower case letters, numbers and hyphens. number of characters 2-50"

    condition = can(regex("^[a-zA-Z0-9-]{2,50}$", var.name))

  }
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "sku" {
  type        = string
  description = "(required) Specify SKU for Azure Recovery Service Vaults. Standard, RS0 (default)"
}

variable "alerts_for_all_job_failures_enabled" {
  type        = bool
  default     = true
  description = "(optional) Specify Setting for Monitoring 'Alerts for All Job Failures'. true (default), false"
}

variable "alerts_for_critical_operation_failures_enabled" {
  type        = bool
  default     = true
  description = "(optional) Specify Setting for Monitoring 'Alerts for Critical Operration Failures'. true (default), false"
}

variable "classic_vmware_replication_enabled" {
  type        = bool
  default     = false
  description = "(option) Specify Setting for Classic VMWare Replication. true, false"
}

variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
An object type defines a customer managed key to use for encryption.

- `key_vault_resource_id` - (Required) - The full Azure Resource ID of the key_vault where the customer managed key will be referenced from.
- `key_name` - (Required) - The full Azur Resource ID of the customer managed Key stored in the key vault
- `key_version` - (Optional) - Customer managed key version
- `user_assigned_identity` - (Optional) - The user assigned identity to use when access the encryption key saved in a key vault


Example Inputs:
```terraform
key_vault_resource_id = {
  key_vault_resource_id = "https://kv-giuh.vault.azure.net/keys/kvk-giuh/0127xxxxx4fdd94cdbd26481a1985"
  key_name  = "https://kv-giuh.vault.azure.net/keys/kvk-giuh/0127xxxxx4fdd94cdbd26481a1985"
  version = null
  user_assigned_identity = {
    resource_id = "/subscriptions/0000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-name"
  }
}
```
DESCRIPTION
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "file_share_backup_policy" {
  type = map(object({
    name     = string
    timezone = string

    frequency = string

    retention_daily = optional(number, null)

    backup = object({
      time = string
      hourly = optional(object({
        interval        = number
        start_time      = string
        window_duration = number
      }))
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
  }))
  default     = null
  description = <<DESCRIPTION
    A map objects for backup and retation options.

    - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
    - `role_assignments` - (Optional) A map of role assignments to create on the 

    - `backup` - (required) backup options.
        - `frequency` - (Required) Sets the backup frequency. Possible values are hourly, Daily and Weekly.
        - `time` - (required) Specify time in a 24 hour format HH:MM. "22:00"
        - `hour_interval` - (Optional) Interval in hour at which backup is triggered. Possible values are 4, 6, 8 and 12. This is used when frequency is hourly. 6
        - `hour_duration` -  (Optional) Duration of the backup window in hours. Possible values are between 4 and 24 This is used when frequency is hourly. 12
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
          frequency     = "hourly"
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

variable "immutability" {
  type        = string
  default     = "Unlocked"
  description = "(optional) Specify Immutability Setting of vault. Locked, Unlocked, Disabled (default)"
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = string
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {
    system_assigned = true
  }
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {}) # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#role-assignments
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)                                        # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#resource-locks
    tags               = optional(map(string), null) # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#tags
    subnet_resource_id = string
    ## You only need to expose the subresource_name if there are multiple underlying services, e.g. storage.
    ## Which has blob, file, etc.
    ## If there is only one then leave this out and hardcode the value in the module.
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "(optional) Specify Public Network Access. true (default), false"
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "soft_delete_enabled" {
  type        = bool
  default     = true
  description = "(optional) Specify Setting for Soft Delete. true (default), false"
}

variable "storage_mode_type" {
  type        = string
  default     = "GeoRedundant"
  description = "(optional) Specify Storage type of the Recovery Services Vault. GeoRedundant (default), LocallyRedundant, ZoneRedundant"

  validation {
    error_message = "Storage Type error: Must be one of the follwoing. GeoRedundant, LocallyRedundant and ZoneRedundant. Defaults to GeoRedundant"
    condition     = can(regex("^[GeoRedundant]|[LocallyRedundant]|[ZoneRedundant]$", var.storage_mode_type))
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "The map of tags to be applied to the resource"
}

variable "vm_backup_policy" {
  type = map(object({
    name                           = string
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
  }))
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

variable "workload_backup_policy" {
  type = map(object({
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
  }))
  default     = null
  description = "(Required)"
}
