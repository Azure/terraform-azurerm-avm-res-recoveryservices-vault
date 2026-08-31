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
  default     = null
  description = "values for backup_protected_file_share module"
}

variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_backup_fabrics_protection_containers                 = optional(list(string), [])
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource owned by this module. Paths use dot notation, e.g. `properties.policyId`.
Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_fabrics_protection_containers` - Paths ignored on the storage account protection container resource.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Paths ignored on the Azure Files protected item resource.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_backup_policies                                      = optional(string, "Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protection_containers                 = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-10-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `recoveryservices_vaults_backup_policies` - Resource type and API version used to look up the existing Azure Files backup policy.
- `recoveryservices_vaults_backup_fabrics_protection_containers` - Resource type and API version for the storage account protection container.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Resource type and API version for the Azure Files protected item.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource created by this module. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource created by this module. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
