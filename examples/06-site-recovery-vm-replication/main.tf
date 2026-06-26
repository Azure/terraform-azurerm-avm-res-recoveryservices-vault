data "azurerm_subscription" "this" {}

resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = "rg-site-recovery-${random_integer.region_seed.result}"
}

resource "random_integer" "region_seed" {
  max = 9999
  min = 1000
}

# Recovery Services Vault with Site Recovery VM replication enabled
module "recovery_services_vault" {
  source = "../../"

  location                                       = azurerm_resource_group.this.location
  name                                           = "rsv-site-recovery-${random_integer.region_seed.result}"
  resource_group_name                            = azurerm_resource_group.this.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false

  # Site Recovery VM replication configuration (requires proper site recovery infrastructure setup)
  site_recovery_replicated_vm = {
    # This is a template configuration. In a real scenario, you would need:
    # 1. Source and target recovery fabrics configured
    # 2. Protection containers created in each fabric
    # 3. A replication policy configured
    # 4. Source and target virtual machines ready
    # 5. Proper network and storage configurations
    
    # Example structure (commented out as it requires existing infrastructure):
    # vm-replication-01 = {
    #   source_vm_id                     = azurerm_virtual_machine.source.id
    #   source_recovery_fabric_name      = azurerm_site_recovery_fabric.primary.name
    #   source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
    #   recovery_replication_policy_id   = azurerm_site_recovery_replication_policy.test.id
    #   target_resource_id               = azurerm_virtual_machine.target.id
    #   target_recovery_fabric_id        = azurerm_site_recovery_fabric.secondary.id
    #   target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
    #   recovery_resource_group_id       = azurerm_resource_group.recovery.id
    # }
  }

  depends_on = [azurerm_resource_group.this]
}

output "rsv" {
  value = module.recovery_services_vault
}
