# Enables Azure Site Recovery (A2A) replication for a virtual machine.
# Replaces the former `resource "azurerm_site_recovery_replicated_vm" "this"`.
resource "azapi_resource" "this" {
  name      = basename(var.site_recovery_replicated_vm.source_vm_id)
  parent_id = local.source_protection_container_id
  type      = local.replication_protected_item_type
  body = {
    properties = {
      policyId                = var.site_recovery_replicated_vm.recovery_replication_policy_id
      providerSpecificDetails = local.provider_specific_details
    }
  }
  read_query_parameters = {
    "api-version" = ["2024-10-01"]
  }
  replace_triggers_refs  = ["properties.providerSpecificDetails.fabricObjectId"]
  response_export_values = ["*"]

  dynamic "timeouts" {
    for_each = var.site_recovery_replicated_vm.timeouts == null ? [] : [var.site_recovery_replicated_vm.timeouts]

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
  type        = local.replication_protected_item_type
  body = {
    properties = merge(local.post_enablement_settings, {
      providerSpecificDetails = {
        instanceType = "A2A"
      }
    })
  }
  method                 = "PATCH"
  response_export_values = []

  dynamic "timeouts" {
    for_each = var.site_recovery_replicated_vm.timeouts == null ? [] : [var.site_recovery_replicated_vm.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
