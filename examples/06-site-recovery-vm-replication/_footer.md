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
