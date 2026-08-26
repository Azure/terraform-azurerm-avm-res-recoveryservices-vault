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

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.14.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.4)

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

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The `azapi_resource` object for the Azure Backup protected item (`Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems`). This is an AzAPI resource object, not the legacy AzureRM `azurerm_backup_protected_vm` object.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ARM resource ID of the Azure Backup protected item.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->