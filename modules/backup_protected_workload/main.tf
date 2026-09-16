locals {
  # Azure Backup addresses a workload container as `VMAppContainer;Compute;<vm resource group>;<vm name>`.
  container_name = "VMAppContainer;Compute;${local.source_vm.resource_group_name};${local.source_vm.name}"
  # The protected item name is `<workload type>;<sql instance name>;<database name>` unless the caller overrides it.
  protected_items = {
    for key, database in var.backup_protected_workload.protected_databases :
    key => {
      name = coalesce(
        database.protected_item_name,
        "${var.backup_protected_workload.workload_type};${database.server_name};${database.database_name}"
      )
      policy_id = coalesce(
        database.workload_backup_policy_id,
        var.backup_protected_workload.workload_backup_policy_id
      )
    }
  }
  source_vm = {
    resource_group_name = local.source_vm_id_parts[1]
    name                = local.source_vm_id_parts[2]
  }
  source_vm_id_parts = regex(
    "(?i)^/subscriptions/([^/]+)/resourceGroups/([^/]+)/providers/Microsoft.Compute/virtualMachines/([^/]+)$",
    var.backup_protected_workload.source_vm_id
  )
  # The inquiry (discovery) operation uses the container workload type rather than the protected item workload type.
  workload_types = {
    SQLDataBase = "SQL"
  }
}

# Register the virtual machine hosting the workload as a `VMAppContainer` with the vault.
# https://learn.microsoft.com/en-us/rest/api/backup/protection-containers/register
resource "azapi_resource" "container" {
  name      = local.container_name
  parent_id = "${var.backup_protected_workload.vault_id}/backupFabrics/Azure"
  type      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers
  body = {
    properties = {
      backupManagementType = "AzureWorkload"
      containerType        = "VMAppContainer"
      friendlyName         = local.source_vm.name
      sourceResourceId     = var.backup_protected_workload.source_vm_id
      workloadType         = local.workload_types[var.backup_protected_workload.workload_type]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers : null
  response_export_values = ["*"]
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# Discover the databases hosted by the registered container so that they can be protected.
# https://learn.microsoft.com/en-us/rest/api/backup/protection-containers/inquire
resource "azapi_resource_action" "inquire" {
  count = var.backup_protected_workload.inquiry_enabled ? 1 : 0

  action = "inquire"
  method = "POST"
  query_parameters = {
    "$filter" = ["workloadType eq '${local.workload_types[var.backup_protected_workload.workload_type]}'"]
  }
  resource_id            = azapi_resource.container.id
  type                   = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers
  response_export_values = []
  retry                  = var.retry
  when                   = "apply"
}

# Registration and discovery are asynchronous, the discovered items are not immediately
# available to the protected item API.
resource "time_sleep" "wait_pre" {
  create_duration = var.backup_protected_workload.sleep_timer

  depends_on = [
    azapi_resource.container,
    azapi_resource_action.inquire
  ]
}

# Protect each selected database.
# https://learn.microsoft.com/en-us/rest/api/backup/protected-items/create-or-update
resource "azapi_resource" "protected_item" {
  for_each = local.protected_items

  name      = each.value.name
  parent_id = azapi_resource.container.id
  type      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  body = {
    properties = {
      policyId          = each.value.policy_id
      protectedItemType = "AzureVmWorkloadSQLDatabase"
      sourceResourceId  = var.backup_protected_workload.source_vm_id
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items : null
  response_export_values = ["*"]
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [time_sleep.wait_pre]
}
