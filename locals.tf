locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

# Role definition resolution.
#
# `var.role_assignments[*].role_definition_id_or_name` accepts either a fully
# qualified role definition resource ID or a role *name* (e.g. "Contributor").
# The AzureRM provider resolved names for us; the ARM API (and therefore AzAPI)
# only accepts resource IDs, so the module performs the lookup itself using
# `data.azapi_resource_list.role_definitions`, which lists the role definitions
# available at subscription scope.
locals {
  # The role definition resource ID to use for each role assignment. Names that cannot
  # be resolved are passed through unchanged so that Azure returns a meaningful error
  # rather than the module failing with an unhelpful lookup error.
  role_assignment_role_definition_resource_ids = {
    for k, v in var.role_assignments : k => (
      strcontains(lower(v.role_definition_id_or_name), lower(local.role_definition_resource_substring))
      ? v.role_definition_id_or_name
      : lookup(local.role_definition_name_to_resource_id, v.role_definition_id_or_name, v.role_definition_id_or_name)
    )
  }
  # Only read the (potentially large) role definition list when at least one role
  # assignment is supplied by name rather than by resource ID.
  role_definition_lookup_enabled = length(local.role_definition_names) > 0
  # The raw results of the lookup, or an empty list when the lookup is disabled.
  role_definition_lookup_results = local.role_definition_lookup_enabled ? try(data.azapi_resource_list.role_definitions[0].output.results, []) : []
  # role name => role definition resource ID. The `null` guard is required because the
  # exported value is a dynamic attribute and can be null when the data source has not
  # been read (for example under provider mocks in the unit tests).
  role_definition_name_to_resource_id = {
    for definition in(local.role_definition_lookup_results == null ? [] : local.role_definition_lookup_results) :
    definition.role_name => definition.id
  }
  # The set of role *names* that must be resolved to role definition resource IDs.
  role_definition_names = toset([
    for _, v in var.role_assignments : v.role_definition_id_or_name
    if !strcontains(lower(v.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  ])
}

# Private endpoint application security group associations
locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  # ARM has no standalone "private endpoint <-> application security group association"
  # resource: the associations are expressed through `properties.applicationSecurityGroups`
  # on the private endpoint itself. The flattened association map above is therefore
  # regrouped per private endpoint key, which keeps the public `var.private_endpoints`
  # interface (a map of associations per endpoint) unchanged. Iterating a map yields
  # keys in lexical order, so the generated list is stable across plans.
  private_endpoint_application_security_group_ids = {
    for pe_k, _ in var.private_endpoints : pe_k => [
      for _, assoc in local.private_endpoint_application_security_group_associations :
      { id = assoc.asg_resource_id } if assoc.pe_key == pe_k
    ]
  }
}

# Private DNS zone group configurations for the private endpoints managed by this module.
locals {
  private_endpoint_dns_zone_configs = {
    for pe_k, pe_v in var.private_endpoints : pe_k => [
      for zone_resource_id in pe_v.private_dns_zone_resource_ids : {
        # A private DNS zone config name is an ARM child resource name and therefore
        # cannot contain `.`; the zone name is converted to the dashed form used by the
        # Azure portal, e.g. `privatelink.blob.core.windows.net` ->
        # `privatelink-blob-core-windows-net`.
        name = replace(basename(zone_resource_id), ".", "-")
        properties = {
          privateDnsZoneId = zone_resource_id
        }
      }
    ]
  }
}

locals {
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
}

locals {
  managed_private_endpoints = {
    for k, v in var.private_endpoints : k => v
    if var.private_endpoints_manage_dns_zone_group
  }
  unmanaged_private_endpoints = {
    for k, v in var.private_endpoints : k => v
    if !var.private_endpoints_manage_dns_zone_group
  }
}
