<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-recoveryservices-vault

This terraform module is designed to deploy Azure Recovery Services Vault. It has support to create private link private endpoints to make the resource privately accessible via customer's private virtual networks and use a customer managed encryption key.

## Features

## Limitations and notes

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 2.4 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) | data source |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_recovery_vault_name"></a> [recovery\_vault\_name](#input\_recovery\_vault\_name) | recovery\_vault\_name: specify a recovery\_vault\_name for the Azure Recovery Services Vault. Upper/Lower case letters, numbers and hyphens. number of characters 2-50 | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_workload_backup_policy"></a> [workload\_backup\_policy](#input\_workload\_backup\_policy) | (Required) | <pre>object({<br>    name          = string<br>    workload_type = string<br>    settings = object({<br>      time_zone           = string<br>      compression_enabled = bool<br>    })<br><br>    backup_frequency = string<br>    protection_policy = map(object({<br>      policy_type           = string # description = "(required) Specify policy type. Full, Differential, Logs"<br>      retention_daily_count = number<br>      retention_weekly = optional(object({<br>        count    = optional(number, null)<br>        weekdays = optional(set(string), null)<br>      }), null)<br>      # retention_daily = optional(number, null) # (Required) The count that is used to count retention duration with duration type Days. Possible values are between 7 and 35.<br>      backup = optional(object({<br>        time                 = optional(string)<br>        frequency_in_minutes = optional(number)<br>        weekdays             = optional(set(string))<br>      }), null)<br><br>      retention_monthly = optional(object({<br>        count             = optional(number, null)<br>        weekdays          = optional(set(string), null)<br>        weeks             = optional(set(string), null)<br>        monthdays         = optional(set(number), null)<br>        include_last_days = optional(bool, false)<br>      }), null)<br><br>      retention_yearly = optional(object({<br>        count             = optional(number, null)<br>        months            = optional(set(string), null)<br>        weekdays          = optional(set(string), null)<br>        weeks             = optional(set(string), null)<br>        monthdays         = optional(set(number), null)<br>        include_last_days = optional(bool, false)<br>      }), null)<br><br>    }))<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_output_protection_policy"></a> [output\_protection\_policy](#output\_output\_protection\_policy) | The output protection policy |
| <a name="output_resource"></a> [resource](#output\_resource) | resource Id output |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | resource Id output |

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->