

data "azurerm_managed_disk" "vm_wus3_osdisk" {
  ##Needed to use a data resource to retrieve the OS disk ID
  name                = azurerm_windows_virtual_machine.vm_wus3.os_disk[0].name
  resource_group_name = azurerm_windows_virtual_machine.vm_wus3.resource_group_name
}
resource "azurerm_windows_virtual_machine" "vm_wus3" {
  name                  = "vm-${azurerm_resource_group.primary_wus3.location}-005"
  location              = azurerm_resource_group.primary_wus3.location
  resource_group_name   = azurerm_resource_group.primary_wus3.name
  size                  = "Standard_D11_v2_Promo" # Standard_D11_v2_Promo 
  admin_username        = "adminuser"
  admin_password        = "P@$$w0rd1234!"
  network_interface_ids = [azurerm_network_interface.vm_wus3.id]
  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  lifecycle {
    ignore_changes = [identity, ]
  }
}
resource "azurerm_network_interface" "vm_wus3" {
  name                = "vm-${azurerm_resource_group.primary_wus3.location}-nic"
  location            = azurerm_resource_group.primary_wus3.location
  resource_group_name = azurerm_resource_group.primary_wus3.name

  ip_configuration {
    name                          = "vm_wus3"
    subnet_id                     = azurerm_subnet.westus3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.westus3.id
  }
}

resource "azurerm_managed_disk" "vm_wus3" {
  name                 = "data-${azurerm_resource_group.primary_wus3.location}-disk"
  location             = azurerm_resource_group.primary_wus3.location
  resource_group_name  = azurerm_resource_group.primary_wus3.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}
resource "azurerm_virtual_machine_data_disk_attachment" "vm_wus3" {
  managed_disk_id    = azurerm_managed_disk.vm_wus3.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm_wus3.id
  lun                = "10"
  caching            = "ReadWrite"
}
resource "azurerm_public_ip" "westus3" {
  name                = "vm-public-ip-${azurerm_resource_group.primary_wus3.location}"
  allocation_method   = "Static"
  location            = azurerm_resource_group.primary_wus3.location
  resource_group_name = azurerm_resource_group.primary_wus3.name
  sku                 = "Basic"
}
resource "azurerm_public_ip" "eastus2" {
  name                = "vm-public-ip-${azurerm_resource_group.secondary_eus2.location}2"
  allocation_method   = "Static"
  location            = azurerm_resource_group.secondary_eus2.location
  resource_group_name = azurerm_resource_group.secondary_eus2.name
  sku                 = "Basic"
}
