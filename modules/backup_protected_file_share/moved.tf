moved {
  from = azurerm_backup_container_storage_account.this
  to   = azapi_resource.protection_container
}

moved {
  from = azurerm_backup_protected_file_share.this
  to   = azapi_resource.this
}
