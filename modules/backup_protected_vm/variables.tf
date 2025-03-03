variable "backup_protected_vm" {
  type = object({
    source_vm_id              = string
    backup_policy_id          = string
    vault_name                = string
    vault_resource_group_name = string
    # timeouts = map(string)

  })
  default = null
}