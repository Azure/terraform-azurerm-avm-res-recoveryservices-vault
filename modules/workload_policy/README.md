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

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.12)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.12)

## Resources

The following resources are used by this module:

- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)

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

### <a name="input_ignore_body_changes"></a> [ignore\_body\_changes](#input\_ignore\_body\_changes)

Description: Body-relative paths to ignore for each AzAPI resource managed by this submodule. Paths use dot notation, for example `properties.settings`.  
List indices are not supported; ignore the whole list property instead.  
This argument is provider-private, so changes take effect only after apply, and ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_policies` - Body-relative paths ignored on the `Microsoft.RecoveryServices/vaults/backupPolicies` resource.

Type:

```hcl
object({
    recoveryservices_vaults_backup_policies = optional(list(string), [])
  })
```

Default: `{}`

### <a name="input_resource_types"></a> [resource\_types](#input\_resource\_types)

Description: AzAPI resource types and API versions used by this submodule.

- `recoveryservices_vaults_backup_policies` - Resource type and API version for the workload backup policy.

Type:

```hcl
object({
    recoveryservices_vaults_backup_policies = optional(string, "Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01")
  })
```

Default: `{}`

### <a name="input_retry"></a> [retry](#input\_retry)

Description: Retry configuration applied to every AzAPI resource managed by this submodule.

- `error_message_regex` - A list of regular expressions matched against the returned error message. A retry is only attempted when one of the expressions matches.
- `interval_seconds` - The initial interval, in seconds, between retries.
- `max_interval_seconds` - The maximum interval, in seconds, between retries.
- `multiplier` - The factor by which the retry interval increases after each attempt.
- `randomization_factor` - The randomization factor applied to the retry interval. Set to `0` to disable jitter.

Type:

```hcl
object({
    error_message_regex  = optional(list(string), ["ReferencedResourceNotProvisioned"])
    interval_seconds     = optional(number, 10)
    max_interval_seconds = optional(number, 180)
    multiplier           = optional(number, 1.5)
    randomization_factor = optional(number, 0.5)
  })
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_timeouts"></a> [timeouts](#input\_timeouts)

Description: Timeouts applied to every AzAPI resource managed by this submodule. Each value is a Go duration string, for example `30m`. A `null` value uses the provider default.

- `create` - The timeout for creating the resource.
- `delete` - The timeout for deleting the resource.
- `read` - The timeout for reading the resource.
- `update` - The timeout for updating the resource.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `{}`

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

### <a name="output_body"></a> [body](#output\_body)

Description: The configured AzAPI request body sent to Azure for the workload backup policy, or `null` when no policy is created.

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the workload backup policy, or `null` when no policy is created.

### <a name="output_output_protection_policy"></a> [output\_protection\_policy](#output\_output\_protection\_policy)

Description: The output protection policy

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the workload backup policy, or `null` when no policy is created.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->