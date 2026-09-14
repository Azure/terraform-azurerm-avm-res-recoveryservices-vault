data "azapi_resource_list" "protectable_items" {
  type                   = var.resource_types.recoveryservices_vaults_backup_fabrics_protectable_items
  parent_id              = local.backup_fabric_id
  response_export_values = ["*"]
  query_parameters = {
    "$filter" = ["backupManagementType eq 'AzureStorage'"]
  }

  depends_on = [time_sleep.wait_pre]
}

data "azapi_resource_list" "protected_items" {
  type                   = var.resource_types.recoveryservices_vaults_backup_protected_items
  parent_id              = local.vault_id
  response_export_values = ["*"]

  depends_on = [time_sleep.wait_pre]
}

resource "azapi_resource" "protection_container" {
  count = var.backup_protected_file_share.disable_registration == true ? 0 : 1

  type      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers
  name      = local.protection_container_name
  parent_id = local.backup_fabric_id
  body = {
    properties = {
      backupManagementType = "AzureStorage"
      containerType        = "StorageContainer"
      friendlyName         = local.source_storage_account_name
      resourceGroup        = local.source_storage_resource_group_name
      sourceResourceId     = var.backup_protected_file_share.source_storage_account_id
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers : null
  response_export_values = [
    "properties.registrationStatus",
  ]
  retry = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource_action" "inquire" {
  type        = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers
  resource_id = var.parent_id
  action      = "inquire"
  method      = "POST"
  query_parameters = {
    "$filter" = ["backupManagementType eq 'AzureStorage'"]
  }
  when = "apply"

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

  depends_on = [azapi_resource.protection_container]
}

resource "time_sleep" "wait_pre" {
  create_duration = var.backup_protected_file_share.sleep_timer

  depends_on = [
    azapi_resource.protection_container,
    azapi_resource_action.inquire,
  ]
}

resource "azapi_resource" "this" {
  type      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  name      = try(local.protectable_item.name, var.backup_protected_file_share.source_file_share_name)
  parent_id = var.parent_id
  body = {
    properties = {
      friendlyName      = var.backup_protected_file_share.source_file_share_name
      policyId          = var.backup_protected_file_share.backup_policy_id
      protectedItemType = "AzureFileShareProtectedItem"
      sourceResourceId  = var.backup_protected_file_share.source_storage_account_id
      workloadType      = "AzureFileShare"
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items : null
  response_export_values = [
    "properties.protectionState",
    "properties.protectionStatus",
  ]
  retry = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    precondition {
      condition     = local.protectable_item != null
      error_message = "The file share was not returned by Azure Backup discovery after registration and inquiry."
    }
  }

  depends_on = [time_sleep.wait_pre]
}