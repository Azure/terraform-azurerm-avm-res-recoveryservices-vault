# Keep existing state from releases where private endpoints were managed by
# azurerm_private_endpoint.this_managed_dns_zone_groups.
moved {
  from = azurerm_private_endpoint.this_managed_dns_zone_groups
  to   = azapi_resource.private_endpoint_managed_dns_zone_groups
}

# Keep existing state from releases where private endpoints were managed by
# azurerm_private_endpoint.this_unmanaged_dns_zone_groups.
moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoint_unmanaged_dns_zone_groups
}

# Application security group associations are now managed in the private
# endpoint request body. Remove the legacy AzureRM association addresses from
# state without modifying their already-managed Azure configuration.
removed {
  from = azurerm_private_endpoint_application_security_group_association.this

  lifecycle {
    destroy = false
  }
}

resource "azapi_resource" "private_endpoint_managed_dns_zone_groups" {
  for_each = local.managed_private_endpoints

  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : length(local.managed_private_endpoints) > 1 ? "pep-${var.name}-${each.key}" : "pep-${var.name}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  type      = var.resource_types.network_private_endpoints
  body = {
    properties = {
      applicationSecurityGroups = [
        for association in values(local.private_endpoint_application_security_group_associations) : {
          id = association.asg_resource_id
        } if association.pe_key == each.key
      ]
      customNetworkInterfaceName = each.value.network_interface_name
      ipConfigurations = [
        for configuration in values(each.value.ip_configurations) : {
          name = configuration.name
          properties = {
            groupId          = each.value.subresource_name
            memberName       = each.value.subresource_name
            privateIPAddress = configuration.private_ip_address
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
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  ignore_null_property   = true
  replace_triggers_refs  = []
  response_export_values = ["*"]
  retry                  = var.retry
  tags                   = each.value.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "private_endpoint_unmanaged_dns_zone_groups" {
  for_each = local.unmanaged_private_endpoints

  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : length(local.unmanaged_private_endpoints) > 1 ? "pep-${var.name}-${each.key}" : "pep-${var.name}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  type      = var.resource_types.network_private_endpoints
  body = {
    properties = {
      applicationSecurityGroups = [
        for association in values(local.private_endpoint_application_security_group_associations) : {
          id = association.asg_resource_id
        } if association.pe_key == each.key
      ]
      customNetworkInterfaceName = each.value.network_interface_name
      ipConfigurations = [
        for configuration in values(each.value.ip_configurations) : {
          name = configuration.name
          properties = {
            groupId          = each.value.subresource_name
            memberName       = each.value.subresource_name
            privateIPAddress = configuration.private_ip_address
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
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  ignore_null_property   = true
  replace_triggers_refs  = []
  response_export_values = ["*"]
  retry                  = var.retry
  tags                   = each.value.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  # Serialize ownership switches so Azure does not cancel overlapping private
  # DNS zone group operations on the same private endpoint.
  depends_on     = [azapi_resource.private_endpoint_managed_dns_zone_groups]
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

# AzAPI resource actions perform a PUT without requiring an import when an
# AzureRM-managed private DNS zone group already exists during an upgrade.
resource "azapi_resource_action" "private_dns_zone_group" {
  for_each = {
    for key, endpoint in local.managed_private_endpoints : key => endpoint
    if length(endpoint.private_dns_zone_resource_ids) > 0
  }

  method      = "PUT"
  resource_id = "${azapi_resource.private_endpoint_managed_dns_zone_groups[each.key].id}/privateDnsZoneGroups/${each.value.private_dns_zone_group_name}"
  type        = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in sort(tolist(each.value.private_dns_zone_resource_ids)) : {
          name = element(reverse(split("/", private_dns_zone_resource_id)), 0)
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    }
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

# Delete module-managed DNS zone groups before their private endpoints are
# deleted. No action is run while this helper resource is being created.
resource "azapi_resource_action" "private_dns_zone_group_delete" {
  for_each = azapi_resource_action.private_dns_zone_group

  method                 = "DELETE"
  resource_id            = each.value.resource_id
  type                   = var.resource_types.network_private_endpoints_private_dns_zone_groups
  ignore_not_found       = true
  response_export_values = []
  retry                  = var.retry
  when                   = "destroy"

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
