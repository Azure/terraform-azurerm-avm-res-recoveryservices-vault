locals {
  # The Azure Backup fabric that hosts Azure Storage containers is always named "Azure".
  backup_fabric_name = "Azure"
  # Azure Backup uses a fixed, documented naming scheme for Azure Files:
  #   container      : storagecontainer;Storage;<storage account resource group>;<storage account name>
  #   protected item : AzureFileShare;<file share name>
  # Both names are fully derivable from the storage account ID and the share name,
  # so no `backupProtectableItems` / `refreshContainers` lookup is required.
  source_storage_account  = provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", var.backup_protected_file_share.source_storage_account_id)
  container_name          = "storagecontainer;Storage;${local.source_storage_account.resource_group_name};${local.source_storage_account.name}"
  protected_item_name     = "AzureFileShare;${var.backup_protected_file_share.source_file_share_name}"
  fabric_id               = "${local.vault_id}/backupFabrics/${local.backup_fabric_name}"
  protection_container_id = "${local.fabric_id}/protectionContainers/${local.container_name}"
  # The root module only passes the vault name and its resource group, so the vault
  # ARM ID is rebuilt here from the current AzAPI client configuration.
  vault_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/resourceGroups/${var.backup_protected_file_share.vault_resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.backup_protected_file_share.vault_name}"
}
