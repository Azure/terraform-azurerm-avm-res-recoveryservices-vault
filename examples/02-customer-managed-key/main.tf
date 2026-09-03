

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

data "azapi_client_config" "this" {}

resource "azapi_resource" "this" {
  location  = local.test_regions[random_integer.region_index.result]
  name      = module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}

locals {
  key_vault_administrator_role_definition_id  = "/subscriptions/${data.azapi_client_config.this.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483"
  key_vault_crypto_officer_role_definition_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/14b46e9e-c2b7-41b4-b07b-48a6ebf60603"
  test_regions                                = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name                                  = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-002"
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "8.0.6"

  azure_region = "westus3"
}

module "recovery_services_vault" {
  source = "../../"

  location                                       = azapi_resource.this.location
  name                                           = local.vault_name #"rsv-test-vault-001"
  resource_group_name                            = azapi_resource.this.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
  customer_managed_key = {
    key_vault_resource_id = azapi_resource.key_vault.id
    key_name              = azapi_resource_action.key_vault_key.output.properties.keyUriWithVersion
    user_assigned_identity = {
      resource_id = azapi_resource.user_assigned_identity.id
    }
  }
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azapi_resource.user_assigned_identity.id]
  }
  public_network_access_enabled = true
  storage_mode_type             = "GeoRedundant"
  tags = {
    env   = "Prod"
    owner = "ABREG0"
    dept  = "IT"
  }

  depends_on = [azapi_resource_action.key_vault_key, azapi_resource.key_vault, ]
}

resource "azapi_resource" "user_assigned_identity" {
  location  = azapi_resource.this.location
  name      = module.naming.user_assigned_identity.name_unique
  parent_id = azapi_resource.this.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = [
    "properties.principalId",
  ]
}

# Wait for Key Vault network settings to take effect before creating the key.
resource "time_sleep" "wait_for_kv" {
  create_duration = "3m"

  depends_on = [azapi_resource.key_vault]
}

# Create a customer-managed key for a Recovery Services Vault.
data "azapi_resource_id" "key_vault_key" {
  name      = module.naming.key_vault_key.name_unique
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.KeyVault/vaults/keys@2023-07-01"
}

resource "azapi_resource_action" "key_vault_key" {
  type        = "Microsoft.KeyVault/vaults/keys@2023-07-01"
  resource_id = data.azapi_resource_id.key_vault_key.id
  method      = "PUT"
  when        = "apply"

  # Key Vault keys don't support management-plane DELETE.
  body = {
    properties = {
      kty     = "RSA"
      keySize = 2048
      keyOps = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
    }
  }
  response_export_values = [
    "properties.keyUriWithVersion",
  ]

  depends_on = [time_sleep.wait_for_kv]
}

#create a keyvault for storing the credential with RBAC for the deployment user
resource "azapi_resource" "key_vault" {
  location  = azapi_resource.this.location
  name      = "${module.naming.key_vault.name_unique}-002"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  body = {
    properties = {
      tenantId = data.azapi_client_config.this.tenant_id
      sku = {
        family = "A"
        name   = "standard"
      }
      enableRbacAuthorization = true
      enableSoftDelete        = true
      # Recovery Services vault CMK encryption requires purge protection on the key vault.
      enablePurgeProtection     = true
      softDeleteRetentionInDays = 7
      publicNetworkAccess       = "Enabled"
      networkAcls = {
        bypass        = "AzureServices"
        defaultAction = "Allow"
      }
    }
  }
  response_export_values = [
    "properties.vaultUri",
  ]
  tags = {
    Dep = "IT"
  }
}

# Grants the deployment user data-plane administration on the key vault.
resource "azapi_resource" "key_vault_administrator" {
  name      = uuidv5("url", "${azapi_resource.key_vault.id}${data.azapi_client_config.this.object_id}${local.key_vault_administrator_role_definition_id}")
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = data.azapi_client_config.this.object_id
      roleDefinitionId = local.key_vault_administrator_role_definition_id
    }
  }
  response_export_values = []
}

# Grants the user-assigned identity access to the customer-managed key.
resource "azapi_resource" "key_vault_crypto_officer" {
  name      = uuidv5("url", "${azapi_resource.key_vault.id}${azapi_resource.user_assigned_identity.output.properties.principalId}${local.key_vault_crypto_officer_role_definition_id}")
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.user_assigned_identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = local.key_vault_crypto_officer_role_definition_id
    }
  }
  response_export_values = []
}
