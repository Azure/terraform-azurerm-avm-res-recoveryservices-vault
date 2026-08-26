

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
  version = "0.4.3"
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "resource_group" {
  location = local.test_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
  body      = {}
}

locals {
  test_regions               = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name                 = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-002"
  key_vault_role_assignments = {
    deployment_user = {
      principal_id       = data.azapi_client_config.current.object_id
      role_definition_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483"
    }
    customer_managed_key = {
      principal_id       = azapi_resource.this_identity.output.properties.principalId
      role_definition_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/14b46e9e-c2b7-41b4-b07b-48a6ebf60603"
    }
  }
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
  customer_managed_key = {
    key_vault_resource_id = azapi_resource.key_vault.id
    key_name              = azapi_resource.key_vault_key.output.properties.keyUriWithVersion
    user_assigned_identity = {
      resource_id = azapi_resource.this_identity.id
    }
  }
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azapi_resource.this_identity.id]
  }
  public_network_access_enabled = true
  storage_mode_type             = "GeoRedundant"
  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }

  depends_on = [azapi_resource.key_vault_key, azapi_resource.key_vault]
}

resource "azapi_resource" "this_identity" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.user_assigned_identity.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  body      = {}

  response_export_values = ["properties.principalId"]
}

# Wait for Key Vault RBAC assignments to propagate before creating the key.
resource "time_sleep" "wait_for_kv" {
  create_duration = "3m"

  depends_on = [azapi_resource.key_vault_role_assignment]
}

# Create a customer-managed key for a Recovery Services Vault.
resource "azapi_resource" "key_vault_key" {
  name      = module.naming.key_vault_key.name_unique
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.KeyVault/vaults/keys@2023-02-01"
  body = {
    properties = {
      keyOps  = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey",
      ]
      keySize = 2048
      kty     = "RSA"
    }
  }

  depends_on = [time_sleep.wait_for_kv]

  response_export_values = ["properties.keyUriWithVersion"]
}

resource "azapi_resource" "key_vault" {
  location  = azapi_resource.resource_group.location
  name      = "${module.naming.key_vault.name_unique}-002"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  body = {
    properties = {
      enableRbacAuthorization = true
      publicNetworkAccess     = "Enabled"
      sku                     = {
        family = "A"
        name   = "standard"
      }
      tenantId                = data.azapi_client_config.current.tenant_id
    }
  }
  tags = {
    Dep = "IT"
  }

  response_export_values = ["properties.vaultUri"]
}

resource "random_uuid" "key_vault_role_assignment" {
  for_each = local.key_vault_role_assignments
}

resource "azapi_resource" "key_vault_role_assignment" {
  for_each = local.key_vault_role_assignments

  name      = random_uuid.key_vault_role_assignment[each.key].result
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = each.value.principal_id
      roleDefinitionId = each.value.role_definition_id
    }
  }
}
