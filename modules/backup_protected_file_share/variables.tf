variable "backup_protected_file_share" {
  type = object({
    source_storage_account_id     = string
    backup_file_share_policy_name = string
    source_file_share_name        = string
    vault_name                    = string
    vault_resource_group_name     = string
    sleep_timer                   = optional(string, "60s")
    disable_registration          = optional(bool, false)
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
