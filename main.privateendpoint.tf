# Private endpoint resources.
#
# Application security group associations have no standalone ARM resource: they are
# expressed through `properties.applicationSecurityGroups` on the private endpoint, so
# the former `azurerm_private_endpoint_application_security_group_association` resource
# is folded into the private endpoint body (see
# `local.private_endpoint_application_security_group_ids`). The public
# `var.private_endpoints` interface is unchanged.

# The PE resource when we **are** managing the private DNS zone group:
resource "azapi_resource" "this_managed_dns_zone_groups" {
  for_each = local.managed_private_endpoints

  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : length(local.managed_private_endpoints) > 1 ? "pep-${var.name}-${each.key}" : "pep-${var.name}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  type      = "Microsoft.Network/privateEndpoints@2024-05-01"
  body = {
    properties = {
      applicationSecurityGroups  = local.private_endpoint_application_security_group_ids[each.key]
      customNetworkInterfaceName = each.value.network_interface_name
      ipConfigurations = [
        for ip_configuration in each.value.ip_configurations : {
          name = ip_configuration.name
          properties = {
            groupId          = each.value.subresource_name
            memberName       = each.value.subresource_name
            privateIPAddress = ip_configuration.private_ip_address
          }
        }
      ]
      privateLinkServiceConnections = [
        {
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : length(local.managed_private_endpoints) > 1 ? "pse-${var.name}-${each.key}" : "pse-${var.name}"
          properties = {
            groupIds             = [each.value.subresource_name]
            privateLinkServiceId = azapi_resource.this.id
          }
        }
      ]
      subnet = {
        id = each.value.subnet_resource_id
      }
    }
  }
  replace_triggers_refs  = []
  response_export_values = ["*"]
  tags                   = each.value.tags

  timeouts {
    create = "60m"
    delete = "60m"
    read   = "5m"
    update = "60m"
  }
}

# Keep existing state from v1.x releases where the private endpoints were managed as
# azurerm_private_endpoint.this_managed_dns_zone_groups.
moved {
  from = azurerm_private_endpoint.this_managed_dns_zone_groups
  to   = azapi_resource.this_managed_dns_zone_groups
}

# With AzAPI the private DNS zone group is modelled as the ARM child resource that it
# actually is, instead of an inline block on the private endpoint resource. It is only
# created for the managed variant; the unmanaged variant simply omits it.
resource "azapi_resource" "this_managed_dns_zone_groups_dns_zone_group" {
  for_each = { for k, v in local.managed_private_endpoints : k => v if length(v.private_dns_zone_resource_ids) > 0 }

  name      = each.value.private_dns_zone_group_name
  parent_id = azapi_resource.this_managed_dns_zone_groups[each.key].id
  type      = "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01"
  body = {
    properties = {
      privateDnsZoneConfigs = local.private_endpoint_dns_zone_configs[each.key]
    }
  }
  replace_triggers_refs  = []
  response_export_values = ["*"]

  timeouts {
    create = "60m"
    delete = "60m"
    read   = "5m"
    update = "60m"
  }
}

# The PE resource when we are **not** managing the private DNS zone group:
resource "azapi_resource" "this_unmanaged_dns_zone_groups" {
  for_each = local.unmanaged_private_endpoints

  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : length(local.unmanaged_private_endpoints) > 1 ? "pep-${var.name}-${each.key}" : "pep-${var.name}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  type      = "Microsoft.Network/privateEndpoints@2024-05-01"
  body = {
    properties = {
      applicationSecurityGroups  = local.private_endpoint_application_security_group_ids[each.key]
      customNetworkInterfaceName = each.value.network_interface_name
      ipConfigurations = [
        for ip_configuration in each.value.ip_configurations : {
          name = ip_configuration.name
          properties = {
            groupId          = each.value.subresource_name
            memberName       = each.value.subresource_name
            privateIPAddress = ip_configuration.private_ip_address
          }
        }
      ]
      privateLinkServiceConnections = [
        {
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : length(local.unmanaged_private_endpoints) > 1 ? "pse-${var.name}-${each.key}" : "pse-${var.name}"
          properties = {
            groupIds             = [each.value.subresource_name]
            privateLinkServiceId = azapi_resource.this.id
          }
        }
      ]
      subnet = {
        id = each.value.subnet_resource_id
      }
    }
  }
  replace_triggers_refs  = []
  response_export_values = ["*"]
  tags                   = each.value.tags

  timeouts {
    create = "60m"
    delete = "60m"
    read   = "5m"
    update = "60m"
  }

  # The AzureRM implementation needed `lifecycle { ignore_changes = [private_dns_zone_group] }`
  # here because the DNS zone group was an inline block of the private endpoint resource,
  # so an externally managed zone group (e.g. created by Azure Policy) appeared as drift.
  # With AzAPI the zone group is a separate ARM child resource
  # (Microsoft.Network/privateEndpoints/privateDnsZoneGroups) that this resource neither
  # declares nor reads, so there is nothing to ignore and the meta-argument is dropped.

  # depends_on ensures that when switching between managed and unmanaged DNS
  # zone group ownership, the managed endpoints are fully destroyed before the
  # unmanaged endpoints are created (and vice-versa for the reverse transition).
  # Without this, Terraform attempts the destroy and create concurrently,
  # causing overlapping ARM operations on the same privateDnsZoneGroups/default
  # resource and a CanceledAndSupersededDueToAnotherOperation error from Azure.
  depends_on = [
    azapi_resource.this_managed_dns_zone_groups,
    azapi_resource.this_managed_dns_zone_groups_dns_zone_group,
  ]
}

# Keep existing state from v1.x releases where the private endpoints were managed as
# azurerm_private_endpoint.this_unmanaged_dns_zone_groups.
moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.this_unmanaged_dns_zone_groups
}

# NOTE: there is deliberately no `moved` block for
# `azurerm_private_endpoint_application_security_group_association.this`: it has no 1:1
# AzAPI replacement because the associations are now part of the private endpoint body.
# Existing state entries must be removed with `terraform state rm` before upgrading.
# See "Upgrading from the AzureRM-based releases" in the README.
