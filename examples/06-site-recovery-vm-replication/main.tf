data "azurerm_subscription" "this" {}

resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = "rg-site-recovery-${random_integer.region_seed.result}"
}

resource "azurerm_resource_group" "target" {
  location = "westus2"
  name     = "rg-site-recovery-target-${random_integer.region_seed.result}"
}

resource "random_integer" "region_seed" {
  max = 9999
  min = 1000
}

resource "random_string" "storage_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "random_password" "vm_admin" {
  length           = 20
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

locals {
  vault_name = "rsv-site-recovery-${random_integer.region_seed.result}"

  source_vms = var.source_vms

  source_vm_data_disks = merge([
    for vm_key, vm in local.source_vms : {
      for disk_key, disk in vm.data_disks : "${vm_key}-${disk_key}" => {
        disk_key = disk_key
        lun      = disk.lun
        size_gb  = disk.size_gb
        vm_key   = vm_key
      }
    }
  ]...)
}

resource "azurerm_virtual_network" "source" {
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "vnet-source-${random_integer.region_seed.result}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_virtual_network" "target" {
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.target.location
  name                = "vnet-target-${random_integer.region_seed.result}"
  resource_group_name = azurerm_resource_group.target.name
}

resource "azurerm_subnet" "source" {
  address_prefixes     = ["10.10.1.0/24"]
  name                 = "snet-source"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.source.name
}

resource "azurerm_subnet" "target" {
  address_prefixes     = ["10.20.1.0/24"]
  name                 = "snet-target"
  resource_group_name  = azurerm_resource_group.target.name
  virtual_network_name = azurerm_virtual_network.target.name
}

resource "azurerm_network_interface" "source" {
  for_each = local.source_vms

  location            = azurerm_resource_group.this.location
  name                = "nic-${each.key}-${random_integer.region_seed.result}"
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.source.id
  }
}

resource "azurerm_windows_virtual_machine" "source" {
  for_each = local.source_vms

  admin_password        = random_password.vm_admin.result
  admin_username        = "azureadmin"
  location              = azurerm_resource_group.this.location
  name                  = "vm-source-${each.key}-${random_integer.region_seed.result}"
  computer_name         = substr(replace("src-${each.key}-${random_integer.region_seed.result}", "-", ""), 0, 15)
  network_interface_ids = [azurerm_network_interface.source[each.key].id]
  resource_group_name   = azurerm_resource_group.this.name
  size                  = "Standard_B2s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "source_data" {
  for_each = local.source_vm_data_disks

  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  location             = azurerm_resource_group.this.location
  name                 = "disk-source-${each.value.vm_key}-${each.value.disk_key}-${random_integer.region_seed.result}"
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "StandardSSD_LRS"
}

resource "azurerm_virtual_machine_data_disk_attachment" "source_data" {
  for_each = local.source_vm_data_disks

  caching            = "ReadWrite"
  lun                = each.value.lun
  managed_disk_id    = azurerm_managed_disk.source_data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.source[each.value.vm_key].id
}

data "azurerm_managed_disk" "source_os" {
  for_each = local.source_vms

  name                = azurerm_windows_virtual_machine.source[each.key].os_disk[0].name
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_storage_account" "staging" {
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = "stasr${random_integer.region_seed.result}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.this.name
}

# Recovery Services Vault with Site Recovery VM replication enabled
module "recovery_services_vault" {
  source = "../../"

  location                                       = azurerm_resource_group.this.location
  name                                           = local.vault_name
  resource_group_name                            = azurerm_resource_group.this.name
  sku                                            = "RS0"
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false

  depends_on = [azurerm_resource_group.this, azurerm_resource_group.target]
}

resource "azurerm_site_recovery_fabric" "primary" {
  location            = azurerm_resource_group.this.location
  name                = "fabric-primary-${random_integer.region_seed.result}"
  recovery_vault_name = local.vault_name
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [module.recovery_services_vault]
}

resource "azurerm_site_recovery_fabric" "secondary" {
  location            = azurerm_resource_group.target.location
  name                = "fabric-secondary-${random_integer.region_seed.result}"
  recovery_vault_name = local.vault_name
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [module.recovery_services_vault]
}

resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "pc-primary-${random_integer.region_seed.result}"
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  recovery_vault_name  = local.vault_name
  resource_group_name  = azurerm_resource_group.this.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  name                 = "pc-secondary-${random_integer.region_seed.result}"
  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
  recovery_vault_name  = local.vault_name
  resource_group_name  = azurerm_resource_group.this.name
}

resource "azurerm_site_recovery_replication_policy" "this" {
  application_consistent_snapshot_frequency_in_minutes = 240
  name                                                 = "replication-policy-${random_integer.region_seed.result}"
  recovery_point_retention_in_minutes                  = 1440
  recovery_vault_name                                  = local.vault_name
  resource_group_name                                  = azurerm_resource_group.this.name

  depends_on = [module.recovery_services_vault]
}

resource "azurerm_site_recovery_protection_container_mapping" "primary_to_secondary" {
  name                                      = "pcm-primary-secondary-${random_integer.region_seed.result}"
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.this.id
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
  recovery_vault_name                       = local.vault_name
  resource_group_name                       = azurerm_resource_group.this.name
}

resource "azurerm_site_recovery_network_mapping" "primary_to_secondary" {
  name                        = "nm-primary-secondary-${random_integer.region_seed.result}"
  recovery_vault_name         = local.vault_name
  resource_group_name         = azurerm_resource_group.this.name
  source_network_id           = azurerm_virtual_network.source.id
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_network_id           = azurerm_virtual_network.target.id
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
}

module "site_recovery_replicated_vm" {
  for_each = local.source_vms

  source = "../../modules/site_recovery_replicated_vm"

  site_recovery_replicated_vm = {
    managed_disk = merge(
      {
        os = {
          disk_id                    = data.azurerm_managed_disk.source_os[each.key].id
          staging_storage_account_id = azurerm_storage_account.staging.id
          target_resource_group_id   = azurerm_resource_group.target.id
        }
      },
      {
        for disk_ref, disk in local.source_vm_data_disks : disk.disk_key => {
          disk_id                    = azurerm_managed_disk.source_data[disk_ref].id
          staging_storage_account_id = azurerm_storage_account.staging.id
          target_resource_group_id   = azurerm_resource_group.target.id
        } if disk.vm_key == each.key
      }
    )
    recovery_replication_policy_id   = azurerm_site_recovery_replication_policy.this.id
    recovery_vault_name              = local.vault_name
    source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
    source_recovery_fabric_name      = azurerm_site_recovery_fabric.primary.name
    source_vm_id                     = azurerm_windows_virtual_machine.source[each.key].id
    target_network_id                = azurerm_virtual_network.target.id
    target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
    target_recovery_fabric_id        = azurerm_site_recovery_fabric.secondary.id
    target_resource_group_id         = azurerm_resource_group.target.id
    target_resource_id               = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${azurerm_resource_group.target.name}/providers/Microsoft.Compute/virtualMachines/vm-target-${each.key}-${random_integer.region_seed.result}"
    target_subnet_name               = azurerm_subnet.target.name
    test_network_id                  = azurerm_virtual_network.target.id
    test_subnet_name                 = azurerm_subnet.target.name
    vault_resource_group_name        = azurerm_resource_group.this.name
  }

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.source_data,
    azurerm_site_recovery_network_mapping.primary_to_secondary,
    azurerm_site_recovery_protection_container_mapping.primary_to_secondary
  ]
}
