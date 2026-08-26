data "azapi_client_config" "current" {}

# Keep existing state from v0.x releases where the vault was managed as
# azurerm_recovery_services_vault.this.
moved {
  from = azurerm_recovery_services_vault.this
  to   = azapi_resource.this
}

# create Recovery vault: https://learn.microsoft.com/en-us/rest/api/recoveryservices/vaults/create-or-update
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = var.resource_types.recoveryservices_vaults
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
      publicNetworkAccess            = var.public_network_access_enabled ? "Enabled" : "Disabled"
      resourceGuardOperationRequests = length(var.resource_guard_operation_requests) > 0 ? var.resource_guard_operation_requests : null
      redundancySettings = {
        standardTierStorageRedundancy = var.storage_mode_type
        crossRegionRestore            = var.cross_region_restore_enabled ? "Enabled" : "Disabled"
      }
      securitySettings = {
        immutabilitySettings = var.immutability != null ? {
          state = var.immutability
        } : null
        softDeleteSettings = {
          softDeleteState = var.soft_delete_enabled
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
        kekIdentity = {
          userAssignedIdentity      = var.customer_managed_key["user_assigned_identity"] != null ? var.customer_managed_key["user_assigned_identity"].resource_id : null
          useSystemAssignedIdentity = var.customer_managed_key["user_assigned_identity"] == null
        }
        infrastructureEncryption = var.customer_managed_key["key_name"] != null ? "Enabled" : "Disabled"
      } : null
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Ignore null body properties (e.g. `identity = null` when no managed identity is
  # configured) so they are not treated as "remove this field" during plan/apply.
  # Without this flag, importing a vault that Azure has auto-assigned an identity to
  # would produce a PUT body without the identity field, causing a 400
  # ManagedIdentityDetailsNotPresent error from the Recovery Services API.
  ignore_body_changes    = length(var.ignore_body_changes.recoveryservices_vaults) > 0 ? var.ignore_body_changes.recoveryservices_vaults : null
  ignore_null_property   = true
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = ["*"]
  retry                  = var.retry
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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

# Keep existing state from releases where diagnostic settings were managed by
# azurerm_monitor_diagnostic_setting.this.
moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}

# Keep existing state from releases where locks were managed by
# azurerm_management_lock.this.
moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

# Keep existing state from releases where role assignments were managed by
# azurerm_role_assignment.this.
moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

# Keep existing state from releases where the Resource Guard association was
# managed by azurerm_recovery_services_vault_resource_guard_association.this.
moved {
  from = azurerm_recovery_services_vault_resource_guard_association.this
  to   = azapi_resource.resource_guard_association
}

data "azapi_resource_list" "role_definitions" {
  for_each = {
    for key, assignment in var.role_assignments : key => assignment
    if !strcontains(lower(assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  }

  type      = var.resource_types.authorization_role_definitions
  parent_id = azapi_resource.this.id

  query_parameters = {
    "$filter" = ["roleName eq '${replace(each.value.role_definition_id_or_name, "'", "''")}'"]
  }

  response_export_values = ["value"]
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      read = timeouts.value.read
    }
  }
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  type      = var.resource_types.insights_diagnostic_settings
  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azapi_resource.this.id

  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      marketplacePartnerId        = each.value.marketplace_partner_resource_id
      storageAccountId            = each.value.storage_account_resource_id
      workspaceId                 = each.value.workspace_resource_id
      logs = concat(
        [for category in each.value.log_categories : {
          category = category
          enabled  = true
        }],
        [for category_group in each.value.log_groups : {
          categoryGroup = category_group
          enabled       = true
        }],
      )
      metrics = [
        for category in each.value.metric_categories : {
          category = category
          enabled  = true
        }
      ]
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  ignore_null_property   = true
  replace_triggers_refs  = []
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

# Apply a lock to the vault when enabled.
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  type      = var.resource_types.authorization_locks
  name      = coalesce(var.lock.name, "lock-${var.name}")
  parent_id = azapi_resource.this.id

  body = {
    properties = {
      level = var.lock.kind
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  replace_triggers_refs  = []
  response_export_values = ["properties.level"]
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

# Set RBAC assignments when defined.
resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  type      = var.resource_types.authorization_role_assignments
  name      = uuidv5("6ba7b810-9dad-11d1-80b4-00c04fd430c8", "${azapi_resource.this.id}|${each.value.role_definition_id_or_name}|${each.value.principal_id}")
  parent_id = azapi_resource.this.id

  body = {
    properties = {
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition != null ? coalesce(each.value.condition_version, "2.0") : each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      description                        = each.value.description
      principalId                        = each.value.principal_id
      principalType                      = each.value.principal_type != null ? each.value.principal_type : each.value.skip_service_principal_aad_check ? "ServicePrincipal" : null
      roleDefinitionId                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : one(data.azapi_resource_list.role_definitions[each.key].output.value).id
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_null_property   = true
  replace_triggers_refs  = []
  response_export_values = ["properties"]
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

  lifecycle {
    # Preserve the provider-generated UUID from the AzureRM state during migration.
    ignore_changes = [name]
  }
}

# Associate a Resource Guard when explicitly enabled.
resource "azapi_resource" "resource_guard_association" {
  count = var.resource_guard_association_enabled ? 1 : 0

  type      = var.resource_types.recoveryservices_vaults_backup_resource_guard_proxies
  name      = "VaultProxy"
  parent_id = azapi_resource.this.id

  body = {
    properties = {
      resourceGuardResourceId = var.resource_guard_id
    }
  }

  ignore_body_changes    = length(var.ignore_body_changes.recoveryservices_vaults_backup_resource_guard_proxies) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_resource_guard_proxies : null
  ignore_null_property   = true
  replace_triggers_refs  = []
  response_export_values = ["properties.resourceGuardResourceId"]
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

# Resource Guard protects the proxy from a normal DELETE. Unlock it before the
# association resource is deleted, mirroring the AzureRM provider behavior.
resource "azapi_resource_action" "resource_guard_association_unlock_delete" {
  for_each = azapi_resource.resource_guard_association

  type        = var.resource_types.recoveryservices_vaults_backup_resource_guard_proxies
  resource_id = each.value.id
  action      = "unlockDelete"
  method      = "POST"
  when        = "destroy"

  body = {
    resourceGuardOperationRequests = [
      "${var.resource_guard_id}/deleteResourceGuardProxyRequests/default",
    ]
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
