locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
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

# Always-on soft delete covers both cloud (softDeleteState) and hybrid (enhancedSecurityState)
# workloads, so both must be sent as "AlwaysON" in the same request. Both fields are extensible
# enums: a mis-cased value, or softDeleteState "AlwaysON" without enhancedSecurityState "AlwaysON",
# is accepted by ARM without error and silently leaves the vault's soft delete state unchanged.
# "AlwaysOn" is accepted for backwards compatibility and normalised to the API value.
locals {
  soft_delete_always_on = contains(["AlwaysON", "AlwaysOn"], var.soft_delete_enabled)
  soft_delete_settings = {
    softDeleteState       = local.soft_delete_always_on ? "AlwaysON" : var.soft_delete_enabled
    enhancedSecurityState = local.soft_delete_always_on ? "AlwaysON" : null
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
