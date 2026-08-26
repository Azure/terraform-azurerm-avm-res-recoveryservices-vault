
# Registers the storage account with the Recovery Services vault.
# Replaces the former `resource "azurerm_backup_container_storage_account" "this"`.
resource "azapi_resource" "storage_container" {
  count = var.backup_protected_file_share.disable_registration == true ? 0 : 1

  name      = local.container_name
  parent_id = local.fabric_id
  type      = local.protection_container_type
  body = {
    properties = {
      backupManagementType = "AzureStorage"
      containerType        = "StorageContainer"
      sourceResourceId     = var.backup_protected_file_share.source_storage_account_id
    }
  }
  read_query_parameters = {
    "api-version" = ["2024-10-01"]
  }
  replace_triggers_refs  = ["properties.sourceResourceId"]
  response_export_values = ["*"]

  dynamic "timeouts" {
    for_each = var.backup_protected_file_share.timeouts == null ? [] : [var.backup_protected_file_share.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
    }
  }
}

resource "time_sleep" "wait_pre" {
  create_duration = var.backup_protected_file_share.sleep_timer

  depends_on = [azapi_resource.storage_container]
}

# Enables Azure Backup protection for a single Azure file share.
# Replaces the former `resource "azurerm_backup_protected_file_share" "this"`.
resource "azapi_resource" "this" {
  name      = local.protected_item_name
  parent_id = local.protection_container_id
  type      = local.protected_item_type
  body = {
    properties = {
      protectedItemType = "AzureFileShareProtectedItem"
      policyId          = data.azapi_resource.this.id
      sourceResourceId  = var.backup_protected_file_share.source_storage_account_id
      # `isInlineInquiry` makes the backup service discover the protectable item for
      # the share as part of this call, which removes the need for a separate
      # `backupProtectableItems` / `refreshContainers` action. The property is accepted
      # by the REST API (and used by the official ARM quickstart templates) but is not
      # present in the published ARM schema for this type, so schema validation is
      # disabled for this resource only.
      isInlineInquiry = true
    }
  }
  read_query_parameters = {
    "api-version" = ["2024-10-01"]
  }
  replace_triggers_refs     = ["properties.sourceResourceId"]
  response_export_values    = ["*"]
  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = var.backup_protected_file_share.timeouts == null ? [] : [var.backup_protected_file_share.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
    }
  }

  depends_on = [time_sleep.wait_pre]
}