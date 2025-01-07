<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-recoveryservices-vault

This terraform module is designed to deploy Azure Recovery Services Vault. It has support to create private link private endpoints to make the resource privately accessible via customer's private virtual networks and use a customer managed encryption key.

## Features

## Limitations and notes

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.107.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.107.0)

## Resources

The following resources are used by this module:

- [azurerm_backup_policy_vm.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_vm) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_recovery_vault_name"></a> [recovery\_vault\_name](#input\_recovery\_vault\_name)

Description: recovery\_vault\_name: specify a recovery\_vault\_name for the Azure Recovery Services Vault. Upper/Lower case letters, numbers and hyphens. number of characters 2-50

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_vm_backup_policy"></a> [vm\_backup\_policy](#input\_vm\_backup\_policy)

Description:     A map objects for backup and retation options.

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
          hour\_interval = 6  
          hour\_duration = 12
          # weekdays      = ["Tuesday", "Saturday"]
        }  
        retention\_daily = 7  
        retention\_weekly = {  
          count    = 7  
          weekdays = ["Monday", "Wednesday"]

        }  
        retention\_monthly = {  
          count = 5
          # weekdays =  ["Tuesday","Saturday"]
          # weeks = ["First","Third"]  
          days = [3, 10, 20]
        }  
        retention\_yearly = {  
          count  = 5  
          months = []
          # weekdays =  ["Tuesday","Saturday"]
          # weeks = ["First","Third"]  
          days = [3, 10, 20]
        }

        }
      }

Type:

```hcl
object({
    name                           = string
    timezone                       = string
    instant_restore_retention_days = optional(number, null)
    instant_restore_resource_group = optional(map(object({
      prefix = optional(string, null)
      suffix = optional(string, null)
    })), {})
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
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: resource Id output

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: resource Id output

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->