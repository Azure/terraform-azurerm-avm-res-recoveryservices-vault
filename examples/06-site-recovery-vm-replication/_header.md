# Site Recovery VM Replication Example

This example demonstrates how to configure a Recovery Services Vault with VM replication for disaster recovery.

## Key Features

- Recovery Services Vault with RS0 SKU
- Site Recovery replication policy
- Site Recovery fabric configuration (source and target)
- VM replication setup
- Protection container mapping
- Network mapping

## Prerequisites

Before applying this example, ensure you have:
- Two Azure regions configured for site recovery
- Source and target resource groups
- Virtual networks in both regions
- Source virtual machines
- Sufficient permissions to create Recovery Services infrastructure

## Usage

```hcl
module "recovery_services_vault" {
  source = "../../"

  location                = azurerm_resource_group.this.location
  name                    = "rsv-site-recovery-001"
  resource_group_name     = azurerm_resource_group.this.name
  sku                     = "RS0"
  
  site_recovery_replicated_vm = {
    vm1 = {
      source_vm_id                     = azurerm_windows_virtual_machine.source.id
      source_recovery_fabric_name      = "fabric-source"
      source_protection_container_name = "container-source"
      recovery_replication_policy_id   = azurerm_site_recovery_replication_policy.example.id
      target_resource_id               = "/subscriptions/.../resourceGroups/rg-target/providers/Microsoft.Compute/virtualMachines/vm-target"
      recovery_resource_group_id       = azurerm_resource_group.target.id
    }
  }
}
```
