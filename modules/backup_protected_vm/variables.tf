variable "backup_protected_vm" {
  type = object({
    source_vm_id              = string
    vm_backup_policy_name          = string
    vault_name                = string
    vault_resource_group_name = string
    # timeouts = map(string)

  })
  default = null
}