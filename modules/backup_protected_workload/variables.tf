variable "backup_protected_workload" {
  type = object({
    vault_id                  = string
    source_vm_id              = string
    workload_backup_policy_id = string
    workload_type             = optional(string, "SQLDataBase")
    inquiry_enabled           = optional(bool, true)
    sleep_timer               = optional(string, "60s")
    protected_databases = map(object({
      server_name               = string
      database_name             = string
      protected_item_name       = optional(string)
      workload_backup_policy_id = optional(string)
    }))
  })
  description = <<DESCRIPTION
Values for the backup_protected_workload module. Registers an Azure virtual machine as a workload (`VMAppContainer`) with the Recovery Services Vault and protects the selected SQL databases hosted on it.

- `vault_id` - (Required) The resource ID of the Recovery Services Vault.
- `source_vm_id` - (Required) The resource ID of the virtual machine hosting the workload.
- `workload_backup_policy_id` - (Required) The resource ID of the workload backup policy to associate with the protected databases.
- `workload_type` - (Optional) The workload type to protect. Only `SQLDataBase` is currently supported.
- `inquiry_enabled` - (Optional) Whether to trigger a workload discovery (inquiry) on the registered container. Defaults to `true`.
- `sleep_timer` - (Optional) Duration to sleep after registration/discovery, to allow for Azure propagation. Defaults to `"60s"`.
- `protected_databases` - (Required) A map of databases to protect. The map key is used as the Terraform address of the protected item so that it stays deterministic when databases are added or removed.
  - `server_name` - (Required) The name of the SQL instance hosting the database, as discovered by Azure Backup (for example `MSSQLSERVER`).
  - `database_name` - (Required) The name of the database to protect.
  - `protected_item_name` - (Optional) Overrides the generated protected item name (`<workload_type>;<server_name>;<database_name>`).
  - `workload_backup_policy_id` - (Optional) Overrides `workload_backup_policy_id` for this database.
DESCRIPTION

  validation {
    condition     = var.backup_protected_workload.workload_type == "SQLDataBase"
    error_message = "Only the `SQLDataBase` workload type is currently supported."
  }
  validation {
    condition     = can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Compute/virtualMachines/[^/]+$", var.backup_protected_workload.source_vm_id))
    error_message = "`source_vm_id` must be the resource ID of an Azure virtual machine."
  }
}

variable "ignore_body_changes" {
  type = object({
    recoveryservices_vaults_backup_fabrics_protection_containers                 = optional(list(string), [])
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths ignored on each AzAPI resource. Paths use dot notation. Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `recoveryservices_vaults_backup_fabrics_protection_containers` - Paths ignored on workload container registration.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Paths ignored on protected SQL database resources.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    recoveryservices_vaults_backup_fabrics_protection_containers                 = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2024-10-01")
    recoveryservices_vaults_backup_fabrics_protection_containers_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-10-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the protected workload submodule.

- `recoveryservices_vaults_backup_fabrics_protection_containers` - Resource type and API version for workload container registration and inquiry.
- `recoveryservices_vaults_backup_fabrics_protection_containers_protected_items` - Resource type and API version for protected SQL databases.
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
  description = "Retry configuration applied to every managed AzAPI resource in the submodule."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "The map of tags to apply to the protected workload resources."
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
