variable "backup_protected_vm" {
  type = object({
    source_vm_id              = string
    vm_backup_policy_name     = string
    vault_name                = string
    vault_resource_group_name = string
    sleep_timer               = optional(string, "60s")
    timeouts = optional(map(object({
      # The timeouts block allows you to specify a duration for the create, delete, read, and update operations.
      create = optional(string, "60m")
      delete = optional(string, "60m")
      read   = optional(string, "60m")
      update = optional(string, "60m")
    })))

  })
  default = null
}
