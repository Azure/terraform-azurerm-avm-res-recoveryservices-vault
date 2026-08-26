data "azapi_client_config" "this" {}

# Looks up the existing Azure Files backup policy by name inside the vault.
# Replaces the former `data "azurerm_backup_policy_file_share" "this"`.
data "azapi_resource" "this" {
  name                   = var.backup_protected_file_share.backup_file_share_policy_name
  type                   = var.resource_types.recoveryservices_vaults_backup_policies
  parent_id              = local.vault_id
  response_export_values = []
}
