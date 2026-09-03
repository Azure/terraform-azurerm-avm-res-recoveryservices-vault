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
