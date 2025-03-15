variable "backup_protected_vm" {
  type = object({
    source_vm_id              = string
    backup_policy_id          = string
    vault_name                = string
    vault_resource_group_name = string
    sleep_timer               = optional(string, "60s")
    timeouts = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "60m")
      read   = optional(string, "60m")
      update = optional(string, "60m")
    }))

  })
  default = null
}