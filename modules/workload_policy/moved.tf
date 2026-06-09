# This removed block handles the state migration from azurerm_backup_policy_vm_workload (used in
# module versions <= v0.3.x) to azapi_resource (used in module versions >= v1.0.0).
# It removes the old resource from state without destroying the underlying Azure resource,
# preventing failures that occur when backup policies have workloads attached.
removed {
  from = azurerm_backup_policy_vm_workload.this

  lifecycle {
    destroy = false
  }
}
