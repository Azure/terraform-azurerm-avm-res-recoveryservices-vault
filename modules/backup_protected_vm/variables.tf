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
  default     = null
  description = "values for backup_protected_vm module"
}

variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource owned by this module. Paths use dot notation, e.g. `properties.policyId`.
Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Paths ignored on the Azure Backup protected item resource.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_backup_policies                                      = optional(string, "Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-10-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `recoveryservices_vaults_backup_policies` - Resource type and API version used to look up the existing VM backup policy.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Resource type and API version for the Azure Backup protected item.
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

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
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

- `create` - The timeout for create operations.
- `delete` - The timeout for delete operations.
- `read` - The timeout for read operations.
- `update` - The timeout for update operations.
DESCRIPTION
  nullable    = false
}
