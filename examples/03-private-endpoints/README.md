<!-- BEGIN_TF_DOCS -->
# Private-endpoints example  

* Example deploy Recovery services vault with private endpoints.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

```hcl


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
  vault_name   = "${module.naming.recovery_services_vault.slug}-${module.azure_region.location_short}-app1-003"
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

  name                                           = local.vault_name
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

  #create a private endpoint for each endpoint type
  private_endpoints = {
    for endpoint in local.endpoints :
    endpoint => {

      # the name must be set to avoid conflicting resources.
      name                          = "pe-${endpoint}-${local.vault_name}"
      subnet_resource_id            = azurerm_subnet.private.id
      subresource_name              = endpoint
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.107.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_network_security_rule.no_internet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone_virtual_network_link.private_links](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_user_assigned_identity.this_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_role_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_bypass_ip_cidr"></a> [bypass\_ip\_cidr](#input\_bypass\_ip\_cidr)

Description: value to bypass the IP CIDR on firewall rules

Type: `string`

Default: `null`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_azure_region"></a> [azure\_region](#module\_azure\_region)

Source: claranet/regions/azurerm

Version: 7.1.1

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.0

### <a name="module_public_ip"></a> [public\_ip](#module\_public\_ip)

Source: lonegunmanb/public-ip/lonegunmanb

Version: 0.1.0

### <a name="module_recovery_services_vault"></a> [recovery\_services\_vault](#module\_recovery\_services\_vault)

Source: ../../

Version:

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: 0.5.2

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->