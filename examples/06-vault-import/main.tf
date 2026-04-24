
# This ensures we have unique CAF compliant names for our resources.
# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.test_regions) - 1
  min = 0
}
# This allows us to randomize the name of resources
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}
# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

resource "azurerm_resource_group" "this" {
  location = local.test_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

locals {
  test_regions = ["eastus", "eastus2", "westus3"]
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-006"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.5.2"
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "7.1.1"

  azure_region = "westus3"
}

# ---------------------------------------------------------------------------
# PHASE 1 – Pre-existing vault
#
# This block represents a Recovery Services Vault that already exists in Azure
# before this module is introduced. In a real scenario you would NOT include
# this block; the vault would simply exist (created manually, via the Azure
# Portal, or by a different Terraform configuration).
#
# The lifecycle rule `ignore_changes = all` prevents Terraform from treating
# drift on this resource as a change, since the module block below is the
# authoritative configuration going forward.
# ---------------------------------------------------------------------------
data "azapi_client_config" "current" {}

resource "azapi_resource" "vault_existing" {
  location  = azurerm_resource_group.this.location
  name      = local.vault_name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.this.name}"
  type      = "Microsoft.RecoveryServices/vaults@2024-10-01"
  body = {
    sku = {
      name = "RS0"
      tier = "Standard"
    }
    properties = {
      publicNetworkAccess = "Enabled"
      redundancySettings = {
        standardTierStorageRedundancy = "GeoRedundant"
        crossRegionRestore            = "Disabled"
      }
      securitySettings = {
        softDeleteSettings = {
          softDeleteState = "Enabled"
        }
      }
    }
  }
  tags = {
    env  = "Prod"
    dept = "IT"
  }

  lifecycle {
    # This resource represents the pre-existing vault state. All ongoing
    # management is delegated to module.recovery_services_vault_imported below.
    # After the first successful apply, remove this resource from state:
    #   terraform state rm 'azapi_resource.vault_existing'
    ignore_changes = all
  }
}

# ---------------------------------------------------------------------------
# PHASE 2 – Import the pre-existing vault into the module
#
# The import block reads the existing vault from Azure and places it under
# management of `module.recovery_services_vault_imported`. On the first apply,
# Terraform will:
#   1. Create (or confirm) the vault via azapi_resource.vault_existing
#   2. Import it into module.recovery_services_vault_imported.azapi_resource.this
#   3. Reconcile any configuration drift
#
# After the first apply completes successfully, run:
#   terraform state rm 'azapi_resource.vault_existing'
# and remove the azapi_resource.vault_existing block from this file so that
# only the module manages the vault going forward.
# ---------------------------------------------------------------------------
import {
  id = azapi_resource.vault_existing.id
  to = module.recovery_services_vault_imported.azapi_resource.this
}

# ---------------------------------------------------------------------------
# PHASE 2 continued – Module managing the imported vault (the "second block")
#
# This module block is the authoritative, ongoing configuration for the vault.
# It matches the settings of the pre-existing vault so that the first apply
# produces no unintended changes.
# ---------------------------------------------------------------------------
module "recovery_services_vault_imported" {
  source = "../../"

  location                                       = azurerm_resource_group.this.location
  name                                           = local.vault_name
  resource_group_name                            = azurerm_resource_group.this.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
  public_network_access_enabled                  = true
  storage_mode_type                              = "GeoRedundant"
  tags = {
    env  = "Prod"
    dept = "IT"
  }

  depends_on = [azapi_resource.vault_existing]
}
