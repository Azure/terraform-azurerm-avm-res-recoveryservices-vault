variable "backup_protected_file_share" {
  type = object({
    backup_policy_id          = string
    disable_registration      = optional(bool, false)
    sleep_timer               = optional(string, "60s")
    source_file_share_name    = string
    source_storage_account_id = string
  })
  nullable    = false
  description = "Configuration for protecting one Azure file share with Azure Backup."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/backupPolicies", var.backup_protected_file_share.backup_policy_id))
    error_message = "`backup_policy_id` must be a valid Recovery Services vault backup policy resource ID."
  }

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", var.backup_protected_file_share.source_storage_account_id))
    error_message = "`source_storage_account_id` must be a valid Azure storage account resource ID."
  }
}

variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_backup_fabrics_protection_containers                 = optional(list(string), [])
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(list(string), [])
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
Body-relative paths ignored on each AzAPI resource. Paths use dot notation.
Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_fabrics_protection_containers` - Paths ignored on storage-account registration. The AzAPI action resource used for inquiry does not expose `ignore_body_changes`.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Paths ignored on the protected file share.
DESCRIPTION
}

variable "parent_id" {
  type        = string
  nullable    = false
  description = "The fully-qualified ARM resource ID of the Azure Backup storage protection container that will contain the protected file share."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers", var.parent_id))
    error_message = "`parent_id` must be a valid Azure Backup protection container resource ID."
  }
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_backup_protected_items                               = optional(string, "Microsoft.RecoveryServices/vaults/backupProtectedItems@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protectable_items                     = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectableItems@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protection_containers                 = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-10-01")
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the protected file share submodule.

- `recoveryservices_vaults_backup_protected_items` - Resource type and API version used to find an existing protected file share.
- `recoveryservices_vaults_backup_fabrics_protectable_items` - Resource type and API version used to discover file shares.
- `recoveryservices_vaults_backup_fabrics_protection_containers` - Resource type and API version for storage-account registration and inquiry.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Resource type and API version for the protected file share.
DESCRIPTION
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to every managed AzAPI resource in the submodule."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to every managed AzAPI resource in the submodule."
}
