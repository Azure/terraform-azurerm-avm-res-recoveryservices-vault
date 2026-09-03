locals {
  backup_fabric_id                   = "${local.vault_id}/backupFabrics/Azure"
  protection_container_name          = basename(var.parent_id)
  source_storage_account_name        = basename(var.backup_protected_file_share.source_storage_account_id)
  source_storage_resource_group_name = split("/", var.backup_protected_file_share.source_storage_account_id)[4]
  vault_id                           = split("/backupFabrics/", var.parent_id)[0]

  matching_protectable_items = [
    for item in data.azapi_resource_list.protectable_items.output.value : item
    if item.properties.friendlyName == var.backup_protected_file_share.source_file_share_name &&
    item.properties.parentContainerFriendlyName == local.source_storage_account_name
  ]
  matching_protected_items = [
    for item in data.azapi_resource_list.protected_items.output.value : item
    if item.properties.friendlyName == var.backup_protected_file_share.source_file_share_name &&
    lower(item.properties.sourceResourceId) == lower(var.backup_protected_file_share.source_storage_account_id)
  ]
  protectable_item = (
    length(local.matching_protectable_items) > 0
    ? one(local.matching_protectable_items)
    : length(local.matching_protected_items) > 0 ? one(local.matching_protected_items) : null
  )
}
