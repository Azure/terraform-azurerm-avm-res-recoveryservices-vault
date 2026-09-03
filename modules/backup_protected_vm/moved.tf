# Terraform `moved` blocks cannot relocate state between two different resource
# types, so the AzureRM -> AzAPI conversion cannot be expressed as a 1:1 `moved`
# block. This `removed` block drops the legacy AzureRM resource from state
# without disabling backup or deleting recovery points in Azure.
#
# See `_header.md` for the `terraform import` command that adopts the existing
# protected item into `azapi_resource.this`.
removed {
  from = azurerm_backup_protected_vm.this

  lifecycle {
    destroy = false
  }
}
