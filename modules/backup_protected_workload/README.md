<!-- BEGIN_TF_DOCS -->
# Default example

* This deploys the module in its simplest form.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.14.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.4)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.14.0)

## Resources

The following resources are used by this module:

- [azapi_resource.container](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.protected_item](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource_action.inquire](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) (resource)
- [time_sleep.wait_pre](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_backup_protected_workload"></a> [backup\_protected\_workload](#input\_backup\_protected\_workload)

Description: Values for the backup\_protected\_workload module. Registers an Azure virtual machine as a workload (`VMAppContainer`) with the Recovery Services Vault and protects the selected SQL databases hosted on it.

- `vault_id` - (Required) The resource ID of the Recovery Services Vault.
- `source_vm_id` - (Required) The resource ID of the virtual machine hosting the workload.
- `workload_backup_policy_id` - (Required) The resource ID of the workload backup policy to associate with the protected databases.
- `workload_type` - (Optional) The workload type to protect. Only `SQLDataBase` is currently supported.
- `inquiry_enabled` - (Optional) Whether to trigger a workload discovery (inquiry) on the registered container. Defaults to `true`.
- `sleep_timer` - (Optional) Duration to sleep after registration/discovery, to allow for Azure propagation. Defaults to `"60s"`.
- `protected_databases` - (Required) A map of databases to protect. The map key is used as the Terraform address of the protected item so that it stays deterministic when databases are added or removed.
  - `server_name` - (Required) The name of the SQL instance hosting the database, as discovered by Azure Backup (for example `MSSQLSERVER`).
  - `database_name` - (Required) The name of the database to protect.
  - `protected_item_name` - (Optional) Overrides the generated protected item name (`<workload_type>;<server_name>;<database_name>`).
  - `workload_backup_policy_id` - (Optional) Overrides `workload_backup_policy_id` for this database.
- `timeouts` - (Optional) The timeouts for the create, delete, read and update operations.

Type:

```hcl
object({
    vault_id                  = string
    source_vm_id              = string
    workload_backup_policy_id = string
    workload_type             = optional(string, "SQLDataBase")
    inquiry_enabled           = optional(bool, true)
    sleep_timer               = optional(string, "60s")
    protected_databases = map(object({
      server_name               = string
      database_name             = string
      protected_item_name       = optional(string)
      workload_backup_policy_id = optional(string)
    }))
    timeouts = optional(object({
      # The timeouts block allows you to specify a duration for the create, delete, read, and update operations.
      create = optional(string, "60m")
      delete = optional(string, "60m")
      read   = optional(string, "60m")
      update = optional(string, "60m")
    }))
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_protected_item_ids"></a> [protected\_item\_ids](#output\_protected\_item\_ids)

Description: A map of the protected item resource IDs, keyed by the `protected_databases` map key.

### <a name="output_protected_item_names"></a> [protected\_item\_names](#output\_protected\_item\_names)

Description: A map of the protected item names, keyed by the `protected_databases` map key.

### <a name="output_protected_items"></a> [protected\_items](#output\_protected\_items)

Description: A map of the protected item resources, keyed by the `protected_databases` map key.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The registered workload protection container resource

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the registered workload protection container

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->