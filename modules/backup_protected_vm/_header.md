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
