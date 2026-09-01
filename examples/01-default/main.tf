

# This ensures we have unique CAF compliant names for our resources.
# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.test_regions) - 1
  min = 0
}
# This allow use to randomize the name of resources
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}
# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "resource_group" {
  location  = local.test_regions[random_integer.region_index.result]
  name      = module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
  body      = {}
}

locals {
  test_regions = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-001"
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "8.0.6"

  azure_region = "westus3"
}

module "recovery_services_vault" {
  source = "../../"

  location                                       = azapi_resource.resource_group.location
  name                                           = local.vault_name #"rsv-test-vault-001"
  resource_group_name                            = azapi_resource.resource_group.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
  public_network_access_enabled                  = true
  storage_mode_type                              = "GeoRedundant"
  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }
}
