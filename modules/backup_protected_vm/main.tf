resource "time_sleep" "wait_pre" {
  create_duration = var.backup_protected_vm.sleep_timer
}

resource "azapi_resource" "this" {
  type      = var.resource_types.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items
  name      = "VM;iaasvmcontainerv2;${local.source_vm_resource_group_name};${local.source_vm_name}"
  parent_id = var.parent_id
  body = {
    properties = {
      friendlyName      = local.source_vm_name
      policyId          = var.backup_protected_vm.backup_policy_id
      protectedItemType = "Microsoft.Compute/virtualMachines"
      sourceResourceId  = var.backup_protected_vm.source_vm_id
      virtualMachineId  = var.backup_protected_vm.source_vm_id
      workloadType      = "VM"
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items) > 0 ? var.ignore_body_changes.recoveryservices_vaults_backup_fabrics_protection_containers_protected_items : null
  response_export_values = [
    "properties.protectionState",
    "properties.protectionStatus",
  ]
  retry = var.retry

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
