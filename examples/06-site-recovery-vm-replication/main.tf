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

  depends_on = [azurerm_resource_group.this]
}
