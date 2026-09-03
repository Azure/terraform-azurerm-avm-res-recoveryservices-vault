variable "backup_protected_vm" {
  type = object({
    backup_policy_id = string
    sleep_timer      = optional(string, "60s")
    source_vm_id     = string
  })
  nullable    = false
  description = "Configuration for protecting one Azure virtual machine with Azure Backup."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/backupPolicies", var.backup_protected_vm.backup_policy_id))
    error_message = "`backup_policy_id` must be a valid Recovery Services vault backup policy resource ID."
  }

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Compute/virtualMachines", var.backup_protected_vm.source_vm_id))
    error_message = "`source_vm_id` must be a valid Azure virtual machine resource ID."
  }
}

variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(list(string), [])
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Body-relative paths ignored on the protected item resource. Paths use dot notation.
Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Paths ignored on the protected virtual machine resource.
DESCRIPTION
}

variable "parent_id" {
  type        = string
  nullable    = false
  description = "The fully-qualified ARM resource ID of the Azure Backup protection container that will contain the protected virtual machine."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers", var.parent_id))
    error_message = "`parent_id` must be a valid Azure Backup protection container resource ID."
  }
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-10-01")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the protected virtual machine submodule.

- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Resource type and API version for the protected virtual machine.
DESCRIPTION
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to the protected virtual machine AzAPI resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to the protected virtual machine AzAPI resource."
}
