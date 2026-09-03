resource "azapi_resource" "network_interface_wus3" {
  type      = "Microsoft.Network/networkInterfaces@2024-05-01"
  name      = "vm-${azapi_resource.resource_group_primary_wus3.location}-nic"
  parent_id = azapi_resource.resource_group_primary_wus3.id
  location  = azapi_resource.resource_group_primary_wus3.location

  body = {
    properties = {
      ipConfigurations = [
        {
          name = "vm_wus3"
          properties = {
            privateIPAllocationMethod = "Dynamic"
            subnet = {
              id = azapi_resource.subnet_westus3.id
            }
          }
        },
      ]
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "managed_disk_wus3" {
  type      = "Microsoft.Compute/disks@2024-03-02"
  name      = "data-${azapi_resource.resource_group_primary_wus3.location}-disk"
  parent_id = azapi_resource.resource_group_primary_wus3.id
  location  = azapi_resource.resource_group_primary_wus3.location

  body = {
    properties = {
      creationData = {
        createOption = "Empty"
      }
      diskSizeGB = 10
    }
    sku = {
      name = "Premium_ZRS"
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_machine_wus3" {
  type      = "Microsoft.Compute/virtualMachines@2024-07-01"
  name      = "vm-${azapi_resource.resource_group_primary_wus3.location}-005"
  parent_id = azapi_resource.resource_group_primary_wus3.id
  location  = azapi_resource.resource_group_primary_wus3.location

  body = {
    identity = {
      type = "SystemAssigned,UserAssigned"
      userAssignedIdentities = {
        (azapi_resource.user_assigned_identity.id) = {}
      }
    }
    properties = {
      hardwareProfile = {
        vmSize = "Standard_D4s_v5"
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.network_interface_wus3.id
            properties = {
              primary = true
            }
          },
        ]
      }
      osProfile = {
        adminUsername = "adminuser"
        computerName  = "vm-wus3-005"
      }
      storageProfile = {
        dataDisks = [
          {
            caching      = "ReadWrite"
            createOption = "Attach"
            lun          = 10
            managedDisk = {
              id = azapi_resource.managed_disk_wus3.id
            }
            name = azapi_resource.managed_disk_wus3.name
          },
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
          managedDisk = {
            storageAccountType = "Premium_ZRS"
          }
        }
      }
    }
  }

  sensitive_body = {
    properties = {
      osProfile = {
        adminPassword = random_password.vm_admin.result
      }
    }
  }

  response_export_values = ["*"]
}
