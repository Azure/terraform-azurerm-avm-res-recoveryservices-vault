

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

data "azapi_client_config" "this" {}

resource "azapi_resource" "this" {
  location  = local.test_regions[random_integer.region_index.result]
  name      = module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
}

locals {
  test_regions = ["eastus", "eastus2", "westus3"] #  "westu2",
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-003"
}

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "8.0.6"

  azure_region = "westus3"
}

locals {
  endpoints           = toset(["AzureBackup", "AzureSiteRecovery", ])
  endpoints_dns_zones = toset(["AzureBackup", "AzureSiteRecovery", "blob", "queue"])
  # AzAPI has no by-name role definition data source. `Contributor` is a built-in
  # role with a well-known, tenant-invariant definition GUID, so the fully
  # qualified subscription-scoped role definition ID is composed directly.
  contributor_role_definition_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  subnet_address_prefix          = "192.168.0.0/24"
}
module "recovery_services_vault" {
  source = "../../"

  location                                       = azapi_resource.this.location
  name                                           = local.vault_name
  resource_group_name                            = azapi_resource.this.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azapi_resource.this_identity.id]
  }
  #create a private endpoint for each endpoint type
  private_endpoints = {
    for endpoint in local.endpoints :
    endpoint => {

      # the name must be set to avoid conflicting resources.
      name                          = "pe-${endpoint}-${local.vault_name}"
      subnet_resource_id            = azapi_resource.private.id
      subresource_name              = endpoint
      private_dns_zone_resource_ids = [azapi_resource.dns_zone[endpoint].id]

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
          role_definition_id_or_name = local.contributor_role_definition_id
          principal_id               = data.azapi_client_config.this.object_id
        }
      }
    }


  }
  public_network_access_enabled = false
  storage_mode_type             = "GeoRedundant"
}

resource "azapi_resource" "vnet" {
  location  = azapi_resource.this.location
  name      = module.naming.virtual_network.name_unique
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.0.0/16"]
      }
    }
  }
}

resource "azapi_resource" "nsg" {
  location  = azapi_resource.this.location
  name      = module.naming.network_security_group.name_unique
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/networkSecurityGroups@2024-05-01"
  body = {
    properties = {}
  }
}

# The network security group association is expressed directly on the subnet body.
resource "azapi_resource" "private" {
  name      = module.naming.subnet.name_unique
  parent_id = azapi_resource.vnet.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = local.subnet_address_prefix
      networkSecurityGroup = {
        id = azapi_resource.nsg.id
      }
    }
  }
}

resource "azapi_resource" "no_internet" {
  name      = module.naming.network_security_rule.name_unique
  parent_id = azapi_resource.nsg.id
  type      = "Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01"
  body = {
    properties = {
      access                   = "Deny"
      destinationAddressPrefix = "Internet"
      destinationPortRange     = "*"
      direction                = "Outbound"
      priority                 = 100
      protocol                 = "*"
      sourceAddressPrefix      = local.subnet_address_prefix
      sourcePortRange          = "*"
    }
  }
}

resource "azapi_resource" "dns_zone" {
  for_each = local.endpoints_dns_zones

  # Private DNS zones are global resources.
  location  = "global"
  name      = each.value == "blob" || each.value == "queue" ? "privatelink.${each.value}.core.windows.net" : each.value == "AzureBackup" ? replace("privatelink.${each.value}.windowsazure.com", "AzureBackup", "${module.azure_region.location_short}.backup") : replace("privatelink.${each.value}.windowsazure.com", "AzureSiteRecovery", "siterecovery")
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/privateDnsZones@2024-06-01"
  body = {
    properties = {}
  }
  tags = {
    env = "Dev"
  }
}

resource "azapi_resource" "private_links" {
  for_each = azapi_resource.dns_zone

  # Private DNS zone virtual network links are global resources.
  location  = "global"
  name      = "${each.key}_${azapi_resource.vnet.name}-link"
  parent_id = each.value.id
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"
  body = {
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azapi_resource.vnet.id
      }
    }
  }
}

resource "azapi_resource" "this_identity" {
  location  = azapi_resource.this.location
  name      = module.naming.user_assigned_identity.name_unique
  parent_id = azapi_resource.this.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
}
