<!-- BEGIN_TF_DOCS -->
# Backup Protected VM

Enables Azure Backup protection for an existing Azure IaaS virtual machine in a Recovery Services vault.

This submodule is implemented entirely with the `Azure/azapi` provider.

## Resources

| Purpose | ARM type | API version |
| --- | --- | --- |
| VM backup policy lookup | `Microsoft.RecoveryServices/vaults/backupPolicies` | `2024-10-01` |
| Protected item | `Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems` | `2024-10-01` |

The backup fabric is always `Azure`. The protection container and protected item names are derived from `backup_protected_vm.source_vm_id`:

* container: `IaasVMContainer;iaasvmcontainerv2;<vm resource group>;<vm name>`
* protected item: `VM;iaasvmcontainerv2;<vm resource group>;<vm name>`

## Migrating from the AzureRM implementation

Terraform `moved` blocks cannot move state between two different resource types, so the `azurerm_backup_protected_vm` -> `azapi_resource` change cannot be expressed as a 1:1 `moved` block. `moved.tf` contains a `removed` block with `destroy = false`, which drops the legacy resource from state without disabling backup or deleting recovery points.

After upgrading, adopt the existing protected item:

```shell
terraform import 'module.<your_module>.module.backup_protected_vm["<key>"].azapi_resource.this' \
  '/subscriptions/<sub>/resourceGroups/<vault rg>/providers/Microsoft.RecoveryServices/vaults/<vault>/backupFabrics/Azure/protectionContainers/IaasVMContainer;iaasvmcontainerv2;<vm rg>;<vm name>/protectedItems/VM;iaasvmcontainerv2;<vm rg>;<vm name>?api-version=2024-10-01'
```

If the import is skipped, Terraform re-issues the enable-protection call, which is idempotent for an already protected VM and does not delete recovery points.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.12)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.14.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.12)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.14.0)

## Resources

The following resources are used by this module:

- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [time_sleep.wait_pre](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azapi_client_config.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_backup_protected_vm"></a> [backup\_protected\_vm](#input\_backup\_protected\_vm)

Description: values for backup\_protected\_vm module

Type:

```hcl
object({
    source_vm_id              = string
    vm_backup_policy_name     = string
    vault_name                = string
    vault_resource_group_name = string
    sleep_timer               = optional(string, "60s")
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

### <a name="input_ignore_body_changes"></a> [ignore\_body\_changes](#input\_ignore\_body\_changes)

Description: Body-relative paths to ignore for each AzAPI resource owned by this module. Paths use dot notation, e.g. `properties.policyId`.  
Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Paths ignored on the Azure Backup protected item resource.

Type:

```hcl
object({
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(list(string), [])
  })
```

Default: `{}`

### <a name="input_resource_types"></a> [resource\_types](#input\_resource\_types)

Description: AzAPI resource types and API versions used by this module.

- `recoveryservices_vaults_backup_policies` - Resource type and API version used to look up the existing VM backup policy.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Resource type and API version for the Azure Backup protected item.

Type:

```hcl
object({
    recoveryservices_vaults_backup_policies                                      = optional(string, "Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-10-01")
  })
```

Default: `{}`

### <a name="input_retry"></a> [retry](#input\_retry)

Description: Retry configuration applied to the AzAPI resources created by this module.

- `error_message_regex` - A list of regular expressions matched against the error message returned by Azure. A matching error is retried.
- `interval_seconds` - The initial number of seconds to wait before the first retry.
- `max_interval_seconds` - The maximum number of seconds to wait between retries.
- `multiplier` - The factor by which the retry interval grows after each attempt.
- `randomization_factor` - The random jitter applied to each retry interval. Set to `0` to disable jitter.

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

Description: Operation timeouts applied to the AzAPI resources created by this module. Values use Go duration strings, e.g. `60m`.

- `create` - The timeout for create operations.
- `delete` - The timeout for delete operations.
- `read` - The timeout for read operations.
- `update` - The timeout for update operations.

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

## Outputs

The following outputs are exported:

### <a name="output_body"></a> [body](#output\_body)

Description: The configured AzAPI request body sent to Azure for the Azure Backup protected item.

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the Azure Backup protected item.

### <a name="output_parent_id"></a> [parent\_id](#output\_parent\_id)

Description: The ARM resource ID of the protection container that contains the Azure Backup protected item.

### <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id)

Description: The ARM resource ID of the backup policy applied to the Azure Backup protected item.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ARM resource ID of the Azure Backup protected item.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->