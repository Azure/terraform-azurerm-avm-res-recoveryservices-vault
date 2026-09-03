# Site Recovery Replicated Virtual Machine

This module defines the configuration for Azure Site Recovery replicated virtual machines.

This submodule is implemented entirely with the `Azure/azapi` provider.

## Resources

| Purpose | ARM type | API version |
| --- | --- | --- |
| Replication protected item | `Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems` | `2024-10-01` |
| Post-enablement target settings (PATCH action) | `Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems` | `2024-10-01` |

The A2A (Azure to Azure) provider is used. Input mapping onto `properties.providerSpecificDetails`:

| Module input | A2A body path |
| --- | --- |
| `source_vm_id` | `fabricObjectId` |
| `target_resource_group_id` / `recovery_resource_group_id` | `recoveryResourceGroupId` |
| `target_protection_container_id` | `recoveryContainerId` |
| `target_network_id` | `recoveryAzureNetworkId` |
| `target_subnet_name` | `recoverySubnetName` |
| `multi_vm_group_name` | `multiVmGroupName` |
| `managed_disk` | `vmManagedDisks[]` (`diskId`, `primaryStagingAzureStorageAccountId`, `recoveryResourceGroupId`, `recoveryTargetDiskAccountType`, `recoveryReplicaDiskAccountType`, `recoveryDiskEncryptionSetId`) |
| `unmanaged_disk` | `vmDisks[]` (`diskUri`, `primaryStagingAzureStorageAccountId`, `recoveryAzureStorageAccountId`) |
| `target_virtual_machine_size` | `recoveryAzureVMSize` (PATCH only) |
| `test_network_id` | `selectedTfoAzureNetworkId` (PATCH only) |

`recoveryAzureVMSize` and `selectedTfoAzureNetworkId` are read-only on the enable-protection (PUT) contract, so they are applied by `azapi_resource_action.target_settings` with `method = "PATCH"` after replication is enabled. This mirrors the follow-up update call the AzureRM provider made internally. Because the action is not refreshed from Azure, later ASR-side changes to those two values do not create drift, preserving the intent of the former `lifecycle.ignore_changes` entries for `target_virtual_machine_size` and `test_network_id`.

Disk drift is handled with body-relative `lifecycle.ignore_changes` on `body.properties.providerSpecificDetails.vmManagedDisks` and `body.properties.providerSpecificDetails.vmDisks`. The NIC details that the former configuration ignored (`network_interface`) map to `vmNics`, which is response-only under AzAPI and therefore never part of the configured body.

`target_recovery_fabric_id` has no equivalent field in the A2A enable-protection contract (the recovery fabric is implied by `recoveryContainerId`); it is accepted for interface compatibility but not sent to Azure.

## Migrating from the AzureRM implementation

Terraform `moved` blocks cannot move state between two different resource types, so the `azurerm_site_recovery_replicated_vm` -> `azapi_resource` change cannot be expressed as a 1:1 `moved` block. `moved.tf` contains a `removed` block with `destroy = false`, which drops the legacy resource from state without disabling replication.

After upgrading, adopt the existing replication protected item:

```shell
terraform import 'module.<your_module>.module.site_recovery_replicated_vm["<key>"].azapi_resource.this' \
  '/subscriptions/<sub>/resourceGroups/<vault rg>/providers/Microsoft.RecoveryServices/vaults/<vault>/replicationFabrics/<source fabric>/replicationProtectionContainers/<source container>/replicationProtectedItems/<vm name>?api-version=2024-10-01'
```

Do not skip the import: without it Terraform re-issues the enable-protection call for an already replicating VM, which the ASR service rejects.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
