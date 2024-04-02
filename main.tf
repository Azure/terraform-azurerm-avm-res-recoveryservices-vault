
# resource gorup data source
data "azurerm_resource_group" "parent" {
  name = var.resource_group_name
}

# create Recovery vault: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault
resource "azurerm_recovery_services_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  public_network_access_enabled = var.public_network_access_enabled
  immutability                  = var.immutability
  storage_mode_type             = var.storage_mode_type
  cross_region_restore_enabled  = var.cross_region_restore_enabled

  soft_delete_enabled = var.soft_delete_enabled

  dynamic "identity" {
    for_each = var.managed_identities != null ? { this = var.managed_identities } : {}

    content {
      type         = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  dynamic "encryption" {
    for_each = (var.customer_managed_key["customer_managed_key_id"] != null) && (var.customer_managed_key != null && length(var.customer_managed_key) > 0) ? { this = var.customer_managed_key } : {}

    content {
      key_id                            = encryption.value.customer_managed_key_id != null ? encryption.value.customer_managed_key_id : null
      infrastructure_encryption_enabled = encryption.value.customer_managed_key_id != null ? true : null
      user_assigned_identity_id         = encryption.value.user_assigned_identity_resource_id != null ? encryption.value.user_assigned_identity_resource_id : null
      use_system_assigned_identity      = encryption.value.user_assigned_identity_resource_id != null ? false : true
    }
  }

  monitoring {
    alerts_for_all_job_failures_enabled            = var.alerts_for_all_job_failures_enabled
    alerts_for_critical_operation_failures_enabled = var.alerts_for_critical_operation_failures_enabled
    # https://learn.microsoft.com/en-us/azure/backup/monitoring-and-alerts-overview
  }

  tags = var.tags

  lifecycle {

  }

}

# apply lock to created resource when enabled
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_recovery_services_vault.this.id
  lock_level = var.lock.kind
}

# set rbac when defined
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                                  = azurerm_recovery_services_vault.this.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}
