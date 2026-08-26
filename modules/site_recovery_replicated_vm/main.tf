# Enables Azure Site Recovery (A2A) replication for a virtual machine.
# Replaces the former `resource "azurerm_site_recovery_replicated_vm" "this"`.
resource "azapi_resource" "this" {
  name      = basename(var.site_recovery_replicated_vm.source_vm_id)
  parent_id = local.source_protection_container_id
  type      = var.resource_types.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items
  body = {
    properties = {
      policyId                = var.site_recovery_replicated_vm.recovery_replication_policy_id
      providerSpecificDetails = local.provider_specific_details
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items) > 0 ? var.ignore_body_changes.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items : null
  read_query_parameters = {
    "api-version" = [local.api_version]
  }
  replace_triggers_refs  = ["properties.providerSpecificDetails.fabricObjectId"]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [local.effective_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Azure Site Recovery mutates these fields after enablement.
  # Ignoring them avoids perpetual replacement loops in subsequent plans.
  # The disk collections are the body-relative equivalents of the former
  # `managed_disk` / `unmanaged_disk` blocks; the NIC details (`vmNics`) are
  # response-only under AzAPI and therefore never part of the configured body.
  lifecycle {
    ignore_changes = [
      body.properties.providerSpecificDetails.vmManagedDisks,
      body.properties.providerSpecificDetails.vmDisks,
    ]
  }
}

# `target_virtual_machine_size` and `test_network_id` are read-only on the
# enable-protection (PUT) contract, so Azure Site Recovery only accepts them
# through the update (PATCH) contract after replication has been enabled. This
# mirrors what the AzureRM provider did internally with a follow-up update call.
# Because the action is not refreshed from Azure, later ASR-side changes to the
# target size or test network do not produce drift, preserving the intent of the
# former `lifecycle.ignore_changes` on those two attributes.
resource "azapi_resource_action" "target_settings" {
  count = length(local.post_enablement_settings) > 0 ? 1 : 0

  resource_id = azapi_resource.this.id
  type        = var.resource_types.recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items
  body = {
    properties = merge(local.post_enablement_settings, {
      providerSpecificDetails = {
        instanceType = "A2A"
      }
    })
  }
  method                 = "PATCH"
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [local.effective_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
