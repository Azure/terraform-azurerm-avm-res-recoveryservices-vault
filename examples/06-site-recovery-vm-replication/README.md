<!-- BEGIN_TF_DOCS -->
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

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.50, < 5.0 |
| <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) | ~> 0.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.50, < 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.1 |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [random_integer.region_seed](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [azurerm_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

<!-- markdownlint-disable MD013 -->
## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rsv"></a> [rsv](#output\_rsv) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_recovery_services_vault"></a> [recovery\_services\_vault](#module\_recovery\_services\_vault) | ../../ | n/a |

## Additional Notes

### Site Recovery Infrastructure Setup

To use VM replication, you need to configure the following Azure Site Recovery components first:

1. **Recovery Fabrics**: Define your source and target Azure regions
2. **Protection Containers**: Containers within each fabric to organize protected items
3. **Replication Policy**: Defines recovery point objectives (RPO) and retention policies
4. **Container Mappings**: Map source containers to target containers
5. **Network Mappings**: Map source virtual networks to target virtual networks
6. **Virtual Machines**: Create or identify VMs to replicate

### Example Setup Flow

```hcl
# 1. Create recovery fabrics
resource "azurerm_site_recovery_fabric" "primary" {
  name                = "fabric-primary"
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  location            = "eastus"
}

resource "azurerm_site_recovery_fabric" "secondary" {
  name                = "fabric-secondary"
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  location            = "westus"
}

# 2. Create protection containers
resource "azurerm_site_recovery_protection_container" "primary" {
  name                = "container-primary"
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

# 3. Create replication policy
resource "azurerm_site_recovery_replication_policy" "test" {
  name                = "test-policy"
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.example.name
  recovery_point_retention_in_minutes = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 60
}

# 4. Then use site_recovery_replicated_vm
```

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve Microsoft products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from end users of your applications that incorporate Microsoft code from the software.

If you are collecting end user data with the software, you must comply with applicable laws, including providing appropriate notices to end users and you should provide a copy of Microsoft's privacy statement to end users (https://privacy.microsoft.com/privacystatement). Microsoft's privacy statement describes the personal data Microsoft processes and the commitments we make about that data.
<!-- END_TF_DOCS -->