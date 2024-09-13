
# create Recovery vault: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault
resource "azurerm_recovery_services_vault" "this" {
  location                           = var.location
  name                               = var.name
  resource_group_name                = var.resource_group_name
  sku                                = var.sku
  classic_vmware_replication_enabled = var.classic_vmware_replication_enabled
  cross_region_restore_enabled       = var.cross_region_restore_enabled
  immutability                       = var.immutability
  public_network_access_enabled      = var.public_network_access_enabled
  soft_delete_enabled                = var.soft_delete_enabled
  storage_mode_type                  = var.storage_mode_type
  tags                               = var.tags

  dynamic "encryption" {
    for_each = var.customer_managed_key != null ? { this = var.customer_managed_key } : {}

    content {
      infrastructure_encryption_enabled = var.customer_managed_key["key_name"] != null ? true : false
      key_id                            = encryption.value.key_name != null ? encryption.value.key_name : null
      use_system_assigned_identity      = encryption.value["user_assigned_identity"] != null ? false : true
      user_assigned_identity_id         = encryption.value["user_assigned_identity"] != null ? encryption.value["user_assigned_identity"].resource_id : null
    }
  }
  ## Resources supporting both SystemAssigned and UserAssigned
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  monitoring {
    alerts_for_all_job_failures_enabled            = var.alerts_for_all_job_failures_enabled
    alerts_for_critical_operation_failures_enabled = var.alerts_for_critical_operation_failures_enabled
  }

  lifecycle {}
}

# diagnostics and settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_recovery_services_vault.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }
}

# apply lock to created resource when enabled
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_recovery_services_vault.this.id
}

# set rbac when defined
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_recovery_services_vault.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
