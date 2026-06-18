# Private endpoint resource and application security group association
resource "azurerm_private_endpoint" "this_managed_dns_zone_groups" {
  for_each = local.managed_private_endpoints

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : length(local.managed_private_endpoints) > 1 ? "pep-${var.name}-${each.key}" : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : length(local.managed_private_endpoints) > 1 ? "pse-${var.name}-${each.key}" : "pse-${var.name}"
    private_connection_resource_id = azapi_resource.this.id
    subresource_names              = [each.value.subresource_name]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = each.value.subresource_name
      subresource_name   = each.value.subresource_name
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  timeouts {
    create = "60m"
    delete = "60m"
    read   = "5m"
    update = "60m"
  }
}

# The PE resource when we are managing **not** the private_dns_zone_group block:
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = local.unmanaged_private_endpoints

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : length(local.unmanaged_private_endpoints) > 1 ? "pep-${var.name}-${each.key}" : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : length(local.unmanaged_private_endpoints) > 1 ? "pse-${var.name}-${each.key}" : "pse-${var.name}"
    private_connection_resource_id = azapi_resource.this.id
    subresource_names              = [each.value.subresource_name]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = each.value.subresource_name
      subresource_name   = each.value.subresource_name
    }
  }

  timeouts {
    create = "60m"
    delete = "60m"
    read   = "5m"
    update = "60m"
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
  # depends_on ensures that when switching between managed and unmanaged DNS
  # zone group ownership, the managed endpoints are fully destroyed before the
  # unmanaged endpoints are created (and vice-versa for the reverse transition).
  # Without this, Terraform attempts the destroy and create concurrently,
  # causing overlapping ARM operations on the same privateDnsZoneGroups/default
  # resource and a CanceledAndSupersededDueToAnotherOperation error from Azure.
  depends_on = [azurerm_private_endpoint.this_managed_dns_zone_groups]
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_key].id : azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_key].id
}
