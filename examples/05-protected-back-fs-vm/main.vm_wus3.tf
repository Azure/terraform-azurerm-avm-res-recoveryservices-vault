

# This file contains the configuration for the Windows Virtual Machine in the West US 3 region.
# It includes the creation of a virtual machine, network interface, managed disk, and public IP address.
resource "azurerm_windows_virtual_machine" "vm_wus3" {
  admin_password        = "P@$$w0rd1234!"
  admin_username        = "adminuser"
  location              = azurerm_resource_group.primary_wus3.location
  name                  = "vm-${azurerm_resource_group.primary_wus3.location}-005"
  network_interface_ids = [azurerm_network_interface.vm_wus3.id]
  resource_group_name   = azurerm_resource_group.primary_wus3.name
  size                  = "Standard_D11_v2_Promo" # Standard_D11_v2_Promo 

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_ZRS"
  }
  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [identity, ]
  }
}
resource "azurerm_network_interface" "vm_wus3" {
  location            = azurerm_resource_group.primary_wus3.location
  name                = "vm-${azurerm_resource_group.primary_wus3.location}-nic"
  resource_group_name = azurerm_resource_group.primary_wus3.name

  ip_configuration {
    name                          = "vm_wus3"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.westus3.id
    subnet_id                     = azurerm_subnet.westus3.id
  }
}

resource "azurerm_managed_disk" "vm_wus3" {
  create_option        = "Empty"
  location             = azurerm_resource_group.primary_wus3.location
  name                 = "data-${azurerm_resource_group.primary_wus3.location}-disk"
  resource_group_name  = azurerm_resource_group.primary_wus3.name
  storage_account_type = "Premium_ZRS"
  disk_size_gb         = 10
}
resource "azurerm_virtual_machine_data_disk_attachment" "vm_wus3" {
  caching            = "ReadWrite"
  lun                = "10"
  managed_disk_id    = azurerm_managed_disk.vm_wus3.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm_wus3.id
}
resource "azurerm_public_ip" "westus3" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.primary_wus3.location
  name                = "vm-public-ip-${azurerm_resource_group.primary_wus3.location}"
  resource_group_name = azurerm_resource_group.primary_wus3.name
  sku                 = "Standard"
  zones               = "1,2,3"
}
resource "azurerm_public_ip" "eastus2" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.secondary_eus2.location
  name                = "vm-public-ip-${azurerm_resource_group.secondary_eus2.location}2"
  resource_group_name = azurerm_resource_group.secondary_eus2.name
  sku                 = "Standard"
  zones               = "1,2,3"
}
