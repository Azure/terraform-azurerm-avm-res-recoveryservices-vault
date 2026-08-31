resource "time_sleep" "wait_pre" {
  create_duration = var.backup_protected_vm.sleep_timer
}

# Enables Azure Backup protection for an Azure IaaS VM.
# Replaces the former `resource "azurerm_backup_protected_vm" "this"`.
resource "azapi_resource" "this" {
  name      = local.protected_item_name
  parent_id = local.protection_container_id
  type      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  body = {
    properties = {
      protectedItemType = "Microsoft.Compute/virtualMachines"
      policyId          = data.azapi_resource.this.id
      sourceResourceId  = var.backup_protected_vm.source_vm_id
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items : null
  read_query_parameters = {
    "api-version" = ["2024-10-01"]
  }
  # The protected item name is derived from the source VM, so a different source VM
  # always means a different protected item; recreate instead of updating in place.
  replace_triggers_refs  = ["properties.sourceResourceId"]
  response_export_values = []
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
