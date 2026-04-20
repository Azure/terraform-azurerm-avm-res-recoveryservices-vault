data "azapi_client_config" "current" {}

moved {
  from = azurerm_recovery_services_vault.this
  to   = azapi_resource.this
}

# create Recovery vault: https://learn.microsoft.com/en-us/rest/api/recoveryservices/vaults/create-or-update
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.RecoveryServices/vaults@2024-10-01"
  body = {
    sku = {
      name = var.sku
      tier = "Standard"
    }
    identity = length(local.managed_identities.system_assigned_user_assigned) > 0 ? {
      type = one(values(local.managed_identities.system_assigned_user_assigned)).type
      userAssignedIdentities = length(one(values(local.managed_identities.system_assigned_user_assigned)).user_assigned_resource_ids) > 0 ? {
        for id in one(values(local.managed_identities.system_assigned_user_assigned)).user_assigned_resource_ids : id => {}
      } : null
    } : null
    properties = {
      publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled"
      redundancySettings = {
        standardTierStorageRedundancy = var.storage_mode_type
        crossRegionRestore            = var.cross_region_restore_enabled ? "Enabled" : "Disabled"
      }
      securitySettings = {
        immutabilitySettings = var.immutability != null ? {
          state = var.immutability
        } : null
        softDeleteSettings = {
          softDeleteState = var.soft_delete_enabled ? "Enabled" : "Disabled"
        }
      }
      monitoringSettings = {
        azureMonitorAlertSettings = {
          alertsForAllJobFailures       = var.alerts_for_all_job_failures_enabled ? "Enabled" : "Disabled"
          alertsForAllReplicationIssues = "Disabled"
          alertsForAllFailoverIssues    = "Disabled"
        }
        classicAlertSettings = {
          alertsForCriticalOperations       = var.alerts_for_critical_operation_failures_enabled ? "Enabled" : "Disabled"
          emailNotificationsForSiteRecovery = "Disabled"
        }
      }
      # Note: classic_vmware_replication_enabled is not directly settable via the vault properties ARM API
      encryption = var.customer_managed_key != null ? {
        keyVaultProperties = {
          keyUri = var.customer_managed_key.key_name
        }
        kekIdentity = var.customer_managed_key["user_assigned_identity"] != null ? {
          userAssignedIdentity      = var.customer_managed_key["user_assigned_identity"].resource_id
          useSystemAssignedIdentity = false
          } : {
          useSystemAssignedIdentity = true
        }
        infrastructureEncryption = var.customer_managed_key["key_name"] != null ? "Enabled" : "Disabled"
      } : null
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["*"]
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {}
}

# diagnostics and settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azapi_resource.this.id
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
  scope      = azapi_resource.this.id
}

# set rbac when defined
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
