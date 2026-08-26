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
          alertsForAllReplicationIssues = var.alerts_for_all_replication_issues_enabled ? "Enabled" : "Disabled"
          alertsForAllFailoverIssues    = var.alerts_for_all_failover_issues_enabled ? "Enabled" : "Disabled"
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
  ignore_null_property   = true
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["*"]
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {}
}

# diagnostics and settings
#
# `Microsoft.Insights/diagnosticSettings` is an extension resource: the parent_id is
# the resource the diagnostic setting is attached to (the vault).
resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      marketplacePartnerId        = each.value.marketplace_partner_resource_id
      storageAccountId            = each.value.storage_account_resource_id
      workspaceId                 = each.value.workspace_resource_id
      logs = setunion(
        [
          for log_group in each.value.log_groups : {
            category      = null
            categoryGroup = log_group
            enabled       = true
          }
        ],
        [
          for log_category in each.value.log_categories : {
            category      = log_category
            categoryGroup = null
            enabled       = true
          }
        ]
      )
      metrics = length(each.value.metric_categories) > 0 ? [
        for metric_category in each.value.metric_categories : {
          category = metric_category
          enabled  = true
        }
      ] : null
    }
  }
  replace_triggers_refs  = []
  response_export_values = ["*"]
}

# Keep existing state from v1.x releases where diagnostic settings were managed as
# azurerm_monitor_diagnostic_setting.this.
moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}

# apply lock to created resource when enabled
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.name}")
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Authorization/locks@2020-05-01"
  body = {
    properties = {
      level = var.lock.kind
    }
  }
  replace_triggers_refs  = []
  response_export_values = ["*"]
}

# Keep existing state from v1.x releases where the lock was managed as
# azurerm_management_lock.this.
moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

# Look up role definitions by name so that `role_definition_id_or_name` can continue
# to accept a role name as well as a role definition resource ID. The ARM role
# assignment API only accepts a role definition resource ID.
data "azapi_resource_list" "role_definitions" {
  count = local.role_definition_lookup_enabled ? 1 : 0

  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

# set rbac when defined
#
# NOTE: ARM has no equivalent of the AzureRM `skip_service_principal_aad_check` flag.
# Supplying `principalType` is the ARM mechanism that skips the Entra ID principal
# existence check, so the flag is mapped onto it when no explicit principal type is
# supplied.
resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  # ARM requires the role assignment name to be a GUID. A deterministic uuidv5 of the
  # scope, principal and role definition keeps the name stable across plans (unlike
  # random_uuid, which requires additional state) while remaining unique per assignment.
  name      = uuidv5("url", "${azapi_resource.this.id}|${each.value.principal_id}|${local.role_assignment_role_definition_resource_ids[each.key]}")
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      description                        = each.value.description
      principalId                        = each.value.principal_id
      principalType                      = each.value.principal_type != null ? each.value.principal_type : (each.value.skip_service_principal_aad_check ? "ServicePrincipal" : null)
      roleDefinitionId                   = local.role_assignment_role_definition_resource_ids[each.key]
    }
  }
  replace_triggers_refs  = []
  response_export_values = ["*"]
}

# Keep existing state from v1.x releases where role assignments were managed as
# azurerm_role_assignment.this.
moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

# associate resource guard when specified
resource "azapi_resource" "resource_guard_association" {
  count = var.resource_guard_id != null ? 1 : 0

  # `RecoveryServicesVault` is the fixed proxy name that the AzureRM provider used, so
  # the association keeps the same ARM resource ID after the state move.
  name      = "RecoveryServicesVault"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.RecoveryServices/vaults/backupResourceGuardProxies@2024-10-01"
  body = {
    properties = {
      resourceGuardResourceId = var.resource_guard_id
    }
  }
  replace_triggers_refs  = []
  response_export_values = ["*"]
}

# Keep existing state from v1.x releases where the resource guard association was
# managed as azurerm_recovery_services_vault_resource_guard_association.this.
moved {
  from = azurerm_recovery_services_vault_resource_guard_association.this
  to   = azapi_resource.resource_guard_association
}
