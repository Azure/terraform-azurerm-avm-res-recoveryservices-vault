variable "site_recovery_replicated_vm" {
  type = object({
    source_vm_id                     = string
    recovery_vault_name              = string
    vault_resource_group_name        = string
    source_recovery_fabric_name      = string
    source_protection_container_name = string
    recovery_replication_policy_id   = string
    target_resource_id               = string
    target_recovery_fabric_id        = optional(string, null)
    target_protection_container_id   = optional(string, null)
    managed_disk = optional(map(object({
      disk_id                    = string
      staging_storage_account_id = string
    })), null)
    unmanaged_disk = optional(map(object({
      disk_uri = string
    })), null)
    target_network_id           = optional(string, null)
    target_subnet_name          = optional(string, null)
    target_static_ip            = optional(string, null)
    test_network_id             = optional(string, null)
    test_subnet_name            = optional(string, null)
    recovery_resource_group_id  = optional(string, null)
    recovery_storage_account_id = optional(string, null)
    recovery_target_disk_encryption_set_id = optional(string, null)
    multi_vm_group_name         = optional(string, null)
    timeouts = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "60m")
      read   = optional(string, "5m")
      update = optional(string, "60m")
    }), {})
  })
  default     = null
  description = "Configuration for site recovery replicated VM"
}
