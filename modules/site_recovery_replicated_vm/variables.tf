variable "site_recovery_replicated_vm" {
  type = object({
    source_vm_id                     = string
    recovery_vault_name              = string
    vault_resource_group_name        = string
    source_recovery_fabric_name      = string
    source_protection_container_name = string
    recovery_replication_policy_id   = string
    target_resource_id               = string
    target_resource_group_id         = optional(string, null)
    target_recovery_fabric_id        = optional(string, null)
    target_protection_container_id   = optional(string, null)
    target_virtual_machine_size      = optional(string, null)
    managed_disk = optional(map(object({
      disk_id                       = string
      staging_storage_account_id    = string
      target_resource_group_id      = optional(string, null)
      target_disk_type              = optional(string, "Standard_LRS")
      target_replica_disk_type      = optional(string, "Standard_LRS")
      target_disk_encryption_set_id = optional(string, null)
    })), null)
    unmanaged_disk = optional(map(object({
      disk_uri                   = string
      staging_storage_account_id = optional(string, null)
      target_storage_account_id  = optional(string, null)
    })), null)
    target_network_id                      = optional(string, null)
    target_subnet_name                     = optional(string, null)
    target_static_ip                       = optional(string, null)
    test_network_id                        = optional(string, null)
    test_subnet_name                       = optional(string, null)
    recovery_resource_group_id             = optional(string, null)
    recovery_storage_account_id            = optional(string, null)
    recovery_target_disk_encryption_set_id = optional(string, null)
    multi_vm_group_name                    = optional(string, null)
    timeouts = optional(object({
      create = optional(string, "60m")
      delete = optional(string, "60m")
      read   = optional(string, "5m")
      update = optional(string, "60m")
    }), {})
  })
  default     = null
  description = "Configuration for site recovery replicated VM. Either target_resource_group_id or recovery_resource_group_id must be set."

  validation {
    condition = (
      var.site_recovery_replicated_vm == null ||
      var.site_recovery_replicated_vm.target_resource_group_id != null ||
      var.site_recovery_replicated_vm.recovery_resource_group_id != null
    )
    error_message = "site_recovery_replicated_vm.target_resource_group_id (or legacy fallback site_recovery_replicated_vm.recovery_resource_group_id) must be provided."
  }
}

variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for the AzAPI resource owned by this module. Paths use dot notation, e.g. `properties.policyId`.
Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items` - Paths ignored on the replication protected item resource.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-10-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items` - Resource type and API version for the Azure Site Recovery replication protected item and its post-enablement update action.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ReferencedResourceNotProvisioned"])
    interval_seconds     = optional(number, 10)
    max_interval_seconds = optional(number, 180)
    multiplier           = optional(number, 1.5)
    randomization_factor = optional(number, 0.5)
  })
  default     = {}
  description = <<DESCRIPTION
Retry configuration applied to the AzAPI resources created by this module.

- `error_message_regex` - A list of regular expressions matched against the error message returned by Azure. A matching error is retried.
- `interval_seconds` - The initial number of seconds to wait before the first retry.
- `max_interval_seconds` - The maximum number of seconds to wait between retries.
- `multiplier` - The factor by which the retry interval grows after each attempt.
- `randomization_factor` - The random jitter applied to each retry interval. Set to `0` to disable jitter.
DESCRIPTION
  nullable    = false
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = {}
  description = <<DESCRIPTION
Operation timeouts applied to the AzAPI resources created by this module. Values use Go duration strings, e.g. `60m`.
Any value set through `site_recovery_replicated_vm.timeouts` takes precedence over the matching value here.

- `create` - The timeout for create operations.
- `delete` - The timeout for delete operations.
- `read` - The timeout for read operations.
- `update` - The timeout for update operations.
DESCRIPTION
  nullable    = false
}
