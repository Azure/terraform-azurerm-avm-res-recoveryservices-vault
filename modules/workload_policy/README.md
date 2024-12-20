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

- [azurerm_backup_policy_vm_workload.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_vm_workload) (resource)

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

### <a name="input_workload_backup_policy"></a> [workload\_backup\_policy](#input\_workload\_backup\_policy)

Description: (Required)

Type:

```hcl
object({
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
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_output_protection_policy"></a> [output\_protection\_policy](#output\_output\_protection\_policy)

Description: The output protection policy

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