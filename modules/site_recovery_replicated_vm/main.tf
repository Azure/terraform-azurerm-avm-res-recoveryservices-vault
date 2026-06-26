resource "azurerm_site_recovery_replicated_vm" "this" {
  name                             = split("/", var.site_recovery_replicated_vm.source_vm_id)[length(split("/", var.site_recovery_replicated_vm.source_vm_id)) - 1]
  resource_group_name              = var.site_recovery_replicated_vm.vault_resource_group_name
  recovery_vault_name              = var.site_recovery_replicated_vm.recovery_vault_name
  source_vm_id                     = var.site_recovery_replicated_vm.source_vm_id
  source_recovery_fabric_name      = var.site_recovery_replicated_vm.source_recovery_fabric_name
  source_protection_container_name = var.site_recovery_replicated_vm.source_protection_container_name
  recovery_replication_policy_id   = var.site_recovery_replicated_vm.recovery_replication_policy_id
  target_resource_id               = var.site_recovery_replicated_vm.target_resource_id
  target_recovery_fabric_id        = var.site_recovery_replicated_vm.target_recovery_fabric_id
  target_protection_container_id   = var.site_recovery_replicated_vm.target_protection_container_id
  target_network_id                = var.site_recovery_replicated_vm.target_network_id
  target_subnet_name               = var.site_recovery_replicated_vm.target_subnet_name
  target_static_ip                 = var.site_recovery_replicated_vm.target_static_ip
  test_network_id                  = var.site_recovery_replicated_vm.test_network_id
  test_subnet_name                 = var.site_recovery_replicated_vm.test_subnet_name
  recovery_resource_group_id       = var.site_recovery_replicated_vm.recovery_resource_group_id
  recovery_storage_account_id      = var.site_recovery_replicated_vm.recovery_storage_account_id
  recovery_target_disk_encryption_set_id = var.site_recovery_replicated_vm.recovery_target_disk_encryption_set_id
  multi_vm_group_name              = var.site_recovery_replicated_vm.multi_vm_group_name
  multi_vm_group_create_option     = var.site_recovery_replicated_vm.multi_vm_group_create_option
  tags                             = var.site_recovery_replicated_vm.tags

  dynamic "managed_disk" {
    for_each = var.site_recovery_replicated_vm.managed_disk == null ? [] : [var.site_recovery_replicated_vm.managed_disk]

    content {
      disk_id                    = each.value.disk_id
      staging_storage_account_id = each.value.staging_storage_account_id
    }
  }

  dynamic "unmanaged_disk" {
    for_each = var.site_recovery_replicated_vm.unmanaged_disk == null ? [] : [var.site_recovery_replicated_vm.unmanaged_disk]

    content {
      disk_uri             = each.value.disk_uri
      staging_storage_name = each.value.staging_storage_name
    }
  }

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
