

# This file contains the configuration for the Windows Virtual Machine in the West US 3 region.
# It includes the creation of a virtual machine, network interface, managed disk, and public IP address.
resource "azapi_resource" "vm_wus3" {
  location  = azapi_resource.rg_primary_wus3.location
  name      = "vm-${azapi_resource.rg_primary_wus3.location}-005"
  parent_id = azapi_resource.rg_primary_wus3.id
  type      = "Microsoft.Compute/virtualMachines@2024-07-01"
  body = {
    identity = {
      type = "SystemAssigned, UserAssigned"
      userAssignedIdentities = {
        (azapi_resource.uami_this.id) = {}
      }
    }
    properties = {
      hardwareProfile = {
        vmSize = "Standard_D4s_v5" # Standard_D11_v2_Promo
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.nic_vm_wus3.id
          }
        ]
      }
      osProfile = {
        adminUsername = "adminuser"
        computerName  = "vm-${azapi_resource.rg_primary_wus3.location}-005"
      }
      storageProfile = {
        dataDisks = [
          {
            caching      = "ReadWrite"
            createOption = "Attach"
            lun          = 10
            managedDisk = {
              id = azapi_resource.disk_vm_wus3.id
            }
          }
        ]
        imageReference = {
          offer     = "WindowsServer"
          publisher = "MicrosoftWindowsServer"
          sku       = "2016-Datacenter"
          version   = "latest"
        }
        osDisk = {
          caching      = "ReadWrite"
          createOption = "FromImage"
          name         = "vm-${azapi_resource.rg_primary_wus3.location}-005-osdisk"
          managedDisk = {
            storageAccountType = "Premium_ZRS"
          }
        }
      }
    }
  }
  # The admin password is write-only and must never be placed in `body`.
  sensitive_body = {
    properties = {
      osProfile = {
        adminPassword = random_password.vm_wus3.result
      }
    }
  }
}

# The VM administrator password is generated rather than hardcoded.
resource "random_password" "vm_wus3" {
  length           = 20
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  special          = true
}

resource "azapi_resource" "nic_vm_wus3" {
  location  = azapi_resource.rg_primary_wus3.location
  name      = "vm-${azapi_resource.rg_primary_wus3.location}-nic"
  parent_id = azapi_resource.rg_primary_wus3.id
  type      = "Microsoft.Network/networkInterfaces@2024-05-01"
  body = {
    properties = {
      ipConfigurations = [
        {
          name = "vm_wus3"
          properties = {
            privateIPAllocationMethod = "Dynamic"
            # publicIPAddress = { id = azapi_resource.pip_westus3.id }
            subnet = {
              id = azapi_resource.snet_westus3.id
            }
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "disk_vm_wus3" {
  location  = azapi_resource.rg_primary_wus3.location
  name      = "data-${azapi_resource.rg_primary_wus3.location}-disk"
  parent_id = azapi_resource.rg_primary_wus3.id
  type      = "Microsoft.Compute/disks@2023-04-02"
  body = {
    sku = {
      name = "Premium_ZRS"
    }
    properties = {
      creationData = {
        createOption = "Empty"
      }
      diskSizeGB = 10
    }
  }
}
# The data disk is attached through the virtual machine body
# (properties.storageProfile.dataDisks) with createOption = "Attach".

# resource "azapi_resource" "pip_westus3" {
#   location  = azapi_resource.rg_primary_wus3.location
#   name      = "vm-public-ip-${azapi_resource.rg_primary_wus3.location}"
#   parent_id = azapi_resource.rg_primary_wus3.id
#   type      = "Microsoft.Network/publicIPAddresses@2024-05-01"
#   body = {
#     sku = {
#       name = "Standard"
#     }
#     zones = ["1", "2", "3"]
#     properties = {
#       publicIPAllocationMethod = "Static"
#     }
#   }
# }
