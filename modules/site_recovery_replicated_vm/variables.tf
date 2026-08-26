variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items = optional(list(string), [])
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
Body-relative paths reserved for the replicated item operations. Paths use dot notation.
Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items` - Reserved for the replicated item. The AzAPI action and update resources currently do not expose `ignore_body_changes`, so non-empty values cannot yet be applied.
DESCRIPTION
}

variable "parent_id" {
  type        = string
  nullable    = false
  description = "The fully-qualified ARM resource ID of the source Site Recovery protection container."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers", var.parent_id))
    error_message = "`parent_id` must be a valid Site Recovery protection container resource ID."
  }
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-04-01")
  })
  default  = {}
  nullable = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the replicated virtual machine submodule.

- `recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items` - Resource type and API version for the replicated item and its actions.
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

variable "site_recovery_replicated_vm" {
  type = object({
    managed_disk = optional(map(object({
      disk_id                       = string
      staging_storage_account_id    = string
      target_disk_encryption_set_id = optional(string)
      target_disk_type              = optional(string, "Standard_LRS")
      target_replica_disk_type      = optional(string, "Standard_LRS")
      target_resource_group_id      = optional(string)
    })))
    multi_vm_group_name                    = optional(string)
    recovery_replication_policy_id         = string
    recovery_resource_group_id             = optional(string)
    recovery_storage_account_id            = optional(string)
    recovery_target_disk_encryption_set_id = optional(string)
    source_vm_id                           = string
    target_network_id                      = optional(string)
    target_protection_container_id         = string
    target_recovery_fabric_id              = optional(string)
    target_resource_group_id               = optional(string)
    target_resource_id                     = optional(string)
    target_static_ip                       = optional(string)
    target_subnet_name                     = optional(string)
    target_virtual_machine_size            = optional(string)
    test_network_id                        = optional(string)
    test_subnet_name                       = optional(string)
    unmanaged_disk = optional(map(object({
      disk_uri                   = string
      staging_storage_account_id = optional(string)
      target_storage_account_id  = optional(string)
    })))
  })
  nullable    = false
  description = "Configuration for one Azure-to-Azure Site Recovery replicated virtual machine."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/replicationPolicies", var.site_recovery_replicated_vm.recovery_replication_policy_id))
    error_message = "`recovery_replication_policy_id` must be a valid Site Recovery replication policy resource ID."
  }

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Compute/virtualMachines", var.site_recovery_replicated_vm.source_vm_id))
    error_message = "`source_vm_id` must be a valid Azure virtual machine resource ID."
  }

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers", var.site_recovery_replicated_vm.target_protection_container_id))
    error_message = "`target_protection_container_id` must be a valid Site Recovery protection container resource ID."
  }

  validation {
    condition     = var.site_recovery_replicated_vm.target_resource_group_id != null || var.site_recovery_replicated_vm.recovery_resource_group_id != null
    error_message = "Either `target_resource_group_id` or the legacy `recovery_resource_group_id` must be provided."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.target_resource_group_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.site_recovery_replicated_vm.target_resource_group_id))
    )
    error_message = "`target_resource_group_id` must be a valid resource group ID or null."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.recovery_resource_group_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.site_recovery_replicated_vm.recovery_resource_group_id))
    )
    error_message = "`recovery_resource_group_id` must be a valid resource group ID or null."
  }

  validation {
    condition = alltrue([
      for disk in values(coalesce(var.site_recovery_replicated_vm.managed_disk, {})) :
      can(provider::azapi::parse_resource_id("Microsoft.Compute/disks", disk.disk_id)) &&
      can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", disk.staging_storage_account_id)) &&
      (disk.target_resource_group_id == null || can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", disk.target_resource_group_id))) &&
      (disk.target_disk_encryption_set_id == null || can(provider::azapi::parse_resource_id("Microsoft.Compute/diskEncryptionSets", disk.target_disk_encryption_set_id)))
    ])
    error_message = "Managed disk resource IDs must have the expected Azure resource types."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.target_network_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", var.site_recovery_replicated_vm.target_network_id))
    )
    error_message = "`target_network_id` must be a valid virtual network ID or null."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.test_network_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", var.site_recovery_replicated_vm.test_network_id))
    )
    error_message = "`test_network_id` must be a valid virtual network ID or null."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.target_recovery_fabric_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.RecoveryServices/vaults/replicationFabrics", var.site_recovery_replicated_vm.target_recovery_fabric_id))
    )
    error_message = "`target_recovery_fabric_id` must be a valid Site Recovery fabric resource ID or null."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.target_resource_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.Compute/virtualMachines", var.site_recovery_replicated_vm.target_resource_id))
    )
    error_message = "`target_resource_id` must be a valid target virtual machine resource ID or null."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.recovery_storage_account_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", var.site_recovery_replicated_vm.recovery_storage_account_id))
    )
    error_message = "`recovery_storage_account_id` must be a valid storage account resource ID or null."
  }

  validation {
    condition = (
      var.site_recovery_replicated_vm.recovery_target_disk_encryption_set_id == null ||
      can(provider::azapi::parse_resource_id("Microsoft.Compute/diskEncryptionSets", var.site_recovery_replicated_vm.recovery_target_disk_encryption_set_id))
    )
    error_message = "`recovery_target_disk_encryption_set_id` must be a valid disk encryption set resource ID or null."
  }

  validation {
    condition = alltrue([
      for disk in values(coalesce(var.site_recovery_replicated_vm.unmanaged_disk, {})) :
      (disk.staging_storage_account_id != null || var.site_recovery_replicated_vm.recovery_storage_account_id != null) &&
      (disk.target_storage_account_id != null || var.site_recovery_replicated_vm.recovery_storage_account_id != null) &&
      (disk.staging_storage_account_id == null || can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", disk.staging_storage_account_id))) &&
      (disk.target_storage_account_id == null || can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", disk.target_storage_account_id)))
    ])
    error_message = "Each unmanaged disk must resolve valid staging and target storage account resource IDs."
  }
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
