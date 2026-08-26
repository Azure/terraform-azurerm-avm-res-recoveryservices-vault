# Terraform `moved` blocks cannot relocate state between two different resource
# types, so the AzureRM -> AzAPI conversion cannot be expressed as 1:1 `moved`
# blocks. These `removed` blocks drop the legacy AzureRM resources from state
# without unregistering the storage account, disabling backup, or deleting
# recovery points in Azure.
#
# See `_header.md` for the `terraform import` commands that adopt the existing
# Azure resources into `azapi_resource.storage_container` and
# `azapi_resource.this`.
removed {
  from = azurerm_backup_container_storage_account.this

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_backup_protected_file_share.this

  lifecycle {
    destroy = false
  }
}
