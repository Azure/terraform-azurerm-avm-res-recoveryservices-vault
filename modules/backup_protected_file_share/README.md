<!-- BEGIN_TF_DOCS -->
# Default example

* This deploys the module in its simplest form.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.13.1)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.13.1)

## Resources

The following resources are used by this module:

- [azurerm_backup_container_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_container_storage_account) (resource)
- [azurerm_backup_protected_file_share.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_file_share) (resource)
- [time_sleep.wait_pre](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azurerm_backup_policy_file_share.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/backup_policy_file_share) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_backup_protected_file_share"></a> [backup\_protected\_file\_share](#input\_backup\_protected\_file\_share)

Description: values for backup\_protected\_file\_share module

Type:

```hcl
object({
    source_storage_account_id     = string
    backup_file_share_policy_name = string
    source_file_share_name        = string
    vault_name                    = string
    vault_resource_group_name     = string
    sleep_timer                   = optional(string, "60s")
    disable_registration          = optional(bool, false)
    timeouts = optional(map(object({
      # The timeouts block allows you to specify a duration for the create, delete, read, and update operations.
      create = optional(string, "60m")
      delete = optional(string, "60m")
      read   = optional(string, "60m")
      update = optional(string, "60m")
    })))

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