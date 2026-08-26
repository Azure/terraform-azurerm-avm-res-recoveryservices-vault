data "azapi_client_config" "this" {}

# Looks up the existing VM backup policy by name inside the vault.
# Replaces the former `data "azurerm_backup_policy_vm" "this"`.
data "azapi_resource" "this" {
  name                   = var.backup_protected_vm.vm_backup_policy_name
  type                   = local.backup_policy_type
  parent_id              = local.vault_id
  response_export_values = []
}
