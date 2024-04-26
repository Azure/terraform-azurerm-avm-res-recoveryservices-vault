

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
  version = "0.4.0"
}

resource "azurerm_resource_group" "this" {
  location = local.test_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

locals {
  test_regions = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-002"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.5.2" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "7.1.1"

  azure_region = "westus3"
}

module "recovery_services_vault" {
  source = "../../"

  name                                           = local.vault_name #"rsv-test-vault-001"
  location                                       = azurerm_resource_group.this.location
  resource_group_name                            = azurerm_resource_group.this.name
  cross_region_restore_enabled                   = false
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  public_network_access_enabled                  = true
  storage_mode_type                              = "GeoRedundant"
  sku                                            = "RS0"

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this_identity.id]
  }
  customer_managed_key = {
    key_vault_resource_id = module.avm_res_keyvault_vault.resource.id
    key_name              = azurerm_key_vault_key.this.id
    user_assigned_identity_resource_id = {
      resource_id = azurerm_user_assigned_identity.this_identity.id
    }
  }

  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }

  depends_on = [azurerm_key_vault_key.this, module.avm_res_keyvault_vault, ]
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "this_identity" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

#Create a Customer Managed Key for a Resovery Services Vautl.
resource "azurerm_key_vault_key" "this" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  key_type     = "RSA"
  key_vault_id = module.avm_res_keyvault_vault.resource.id
  name         = module.naming.key_vault_key.name_unique
  key_size     = 2048

  depends_on = [module.avm_res_keyvault_vault]
}

#create a keyvault for storing the credential with RBAC for the deployment user
module "avm_res_keyvault_vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = "0.5.1"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = "${module.naming.key_vault.name_unique}-002"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  network_acls = {
    default_action = "Allow"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }

    customer_managed_key = {
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = azurerm_user_assigned_identity.this_identity.principal_id
    }
  }


  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
  tags = {
    Dep = "IT"
  }
}

