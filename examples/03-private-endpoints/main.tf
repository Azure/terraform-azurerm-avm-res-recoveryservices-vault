

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
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-001"
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

locals {
  endpoints           = toset(["AzureBackup", "AzureSiteRecovery", ])
  endpoints_dns_zones = toset(["AzureBackup", "AzureSiteRecovery", "blob", "queue"])
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
  public_network_access_enabled                  = false
  storage_mode_type                              = "GeoRedundant"
  sku                                            = "RS0"

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this_identity.id]
  }
  customer_managed_key = {
    key_vault_resource_id = module.avm_res_keyvault_vault.resource.id
    key_name              = azurerm_key_vault_key.this.name
    user_assigned_identity_resource_id = {
      resource_id = azurerm_user_assigned_identity.this_identity.id
    }
  }

  #create a private endpoint for each endpoint type
  private_endpoints = {
    for endpoint in local.endpoints :
    endpoint => {

      # the name must be set to avoid conflicting resources.
      name                          = "pe-${endpoint}-${local.vault_name}"
      subnet_resource_id            = azurerm_subnet.private.id
      subresource_name              = [endpoint]
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.this[endpoint].id]

      # these are optional but illustrate making well-aligned service connection & NIC names.
      private_service_connection_name = "psc-${endpoint}-${local.vault_name}"
      network_interface_name          = "nic-pe-${endpoint}-${local.vault_name}"
      inherit_tags                    = false
      inherit_lock                    = false

      tags = {
        env   = "Prod"
        owner = "ABREG0 "
        dept  = "IT"
      }

      role_assignments = {
        role_assignment_1 = {
          role_definition_id_or_name = data.azurerm_role_definition.this.id
          principal_id               = data.azurerm_client_config.current.object_id
        }
      }
    }


  }

}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "private" {
  address_prefixes     = ["192.168.0.0/24"]
  name                 = module.naming.subnet.name_unique
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_network_security_group" "nsg" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.network_security_group.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet_network_security_group_association" "private" {
  network_security_group_id = azurerm_network_security_group.nsg.id
  subnet_id                 = azurerm_subnet.private.id
}

resource "azurerm_network_security_rule" "no_internet" {
  access                      = "Deny"
  direction                   = "Outbound"
  name                        = module.naming.network_security_rule.name_unique
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 100
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.this.name
  destination_address_prefix  = "Internet"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_subnet.private.address_prefixes[0]
  source_port_range           = "*"
}

module "public_ip" {
  count = var.bypass_ip_cidr == null ? 1 : 0

  source  = "lonegunmanb/public-ip/lonegunmanb"
  version = "0.1.0"
}

resource "azurerm_private_dns_zone" "this" {
  for_each = local.endpoints_dns_zones

  name                = each.value == "blob" || each.value == "queue" ? "privatelink.${each.value}.core.windows.net" : each.value == "AzureBackup" ? replace("privatelink.${each.value}.windowsazure.com", "AzureBackup", "${module.azure_region.location_short}.backup") : replace("privatelink.${each.value}.windowsazure.com", "AzureSiteRecovery", "siterecovery")
  resource_group_name = azurerm_resource_group.this.name
  tags = {
    env = "Dev"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_links" {
  for_each = azurerm_private_dns_zone.this

  name                  = "${each.key}_${azurerm_virtual_network.vnet.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "this_identity" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

data "azurerm_role_definition" "this" {
  name = "Contributor"
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
  name                = module.naming.key_vault.name_unique
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
