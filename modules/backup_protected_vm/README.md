<!-- BEGIN_TF_DOCS -->
# Default example

* This deploys the module in its simplest form.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.7, < 5.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.7, < 5.0.0 |
| <a name="provider_time"></a> [time](#provider\_time) | ~> 0.14.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_backup_protected_vm.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) | resource |
| [time_sleep.wait_pre](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_backup_policy_vm.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/backup_policy_vm) | data source |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_protected_vm"></a> [backup\_protected\_vm](#input\_backup\_protected\_vm) | values for backup\_protected\_vm module | <pre>object({<br>    source_vm_id              = string<br>    vm_backup_policy_name     = string<br>    vault_name                = string<br>    vault_resource_group_name = string<br>    sleep_timer               = optional(string, "60s")<br>    timeouts = optional(map(object({<br>      # The timeouts block allows you to specify a duration for the create, delete, read, and update operations.<br>      create = optional(string, "60m")<br>      delete = optional(string, "60m")<br>      read   = optional(string, "60m")<br>      update = optional(string, "60m")<br>    })))<br><br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource"></a> [resource](#output\_resource) | resource Id output |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | resource Id output |

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->