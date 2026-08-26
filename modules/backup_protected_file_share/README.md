<!-- BEGIN_TF_DOCS -->
# Backup Protected File Share

Registers a storage account with a Recovery Services vault and enables Azure Backup protection for one Azure file share.

This submodule is implemented entirely with the `Azure/azapi` provider.

## Resources

| Purpose | ARM type | API version |
| --- | --- | --- |
| Azure Files backup policy lookup | `Microsoft.RecoveryServices/vaults/backupPolicies` | `2024-10-01` |
| Storage account registration | `Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers` | `2024-10-01` |
| Protected item | `Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems` | `2024-10-01` |

The backup fabric is always `Azure`. The container and protected item names are fully derivable, so no `backupProtectableItems` / `refreshContainers` action is required:

* container: `storagecontainer;Storage;<storage account resource group>;<storage account name>`
* protected item: `AzureFileShare;<file share name>`

The protected item body sets `properties.isInlineInquiry = true` so the backup service discovers the protectable item for the share as part of the enable-protection call. That property is accepted by the REST API and used by the official ARM quickstart templates, but it is not published in the ARM schema for this type, so `schema_validation_enabled = false` is set on that resource only.

`time_sleep.wait_pre` (controlled by `backup_protected_file_share.sleep_timer`) still runs between the storage account registration and the protected item, exactly as before.

## Migrating from the AzureRM implementation

Terraform `moved` blocks cannot move state between two different resource types, so the AzureRM -> AzAPI change cannot be expressed as 1:1 `moved` blocks. `moved.tf` contains `removed` blocks with `destroy = false`, which drop the legacy resources from state without unregistering the storage account, disabling backup, or deleting recovery points.

After upgrading, adopt the existing Azure resources:

```shell
# Storage account registration (omit when disable_registration = true)
terraform import 'module.<your_module>.module.backup_protected_file_share["<key>"].azapi_resource.storage_container[0]' \
  '/subscriptions/<sub>/resourceGroups/<vault rg>/providers/Microsoft.RecoveryServices/vaults/<vault>/backupFabrics/Azure/protectionContainers/storagecontainer;Storage;<sa rg>;<sa name>?api-version=2024-10-01'

# Protected file share
terraform import 'module.<your_module>.module.backup_protected_file_share["<key>"].azapi_resource.this' \
  '/subscriptions/<sub>/resourceGroups/<vault rg>/providers/Microsoft.RecoveryServices/vaults/<vault>/backupFabrics/Azure/protectionContainers/storagecontainer;Storage;<sa rg>;<sa name>/protectedItems/AzureFileShare;<share name>?api-version=2024-10-01'
```

If the existing protected item was created by the AzureRM provider, its name may be the service generated `AzureFileShare;<protectable item id>` form rather than `AzureFileShare;<share name>`. Both forms address the same backup item; import using the name reported by `az backup item list`, or let Terraform re-issue the (idempotent) enable-protection call.

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

- [azapi_resource.storage_container](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [time_sleep.wait_pre](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azapi_client_config.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)

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

Description: The `azapi_resource` object for the Azure Files protected item (`Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems`). This is an AzAPI resource object, not the legacy AzureRM `azurerm_backup_protected_file_share` object.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ARM resource ID of the Azure Files protected item.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->