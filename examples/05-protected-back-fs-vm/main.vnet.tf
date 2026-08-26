resource "azapi_resource" "vnet_westus1" {
  location  = azapi_resource.rg_primary_wus1.location
  name      = "vnet-${azapi_resource.rg_primary_wus1.location}"
  parent_id = azapi_resource.rg_primary_wus1.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.1.0/24"]
      }
    }
  }
}
# output "vnet" {
#   value = azapi_resource.vnet_westus1
# }
resource "azapi_resource" "snet_westus1" {
  name      = "snet-${azapi_resource.rg_primary_wus1.location}"
  parent_id = azapi_resource.vnet_westus1.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.1.0/24"
    }
  }
}
resource "azapi_resource" "vnet_westus2" {
  location  = azapi_resource.rg_primary_wus2.location
  name      = "vnet-${azapi_resource.rg_primary_wus2.location}"
  parent_id = azapi_resource.rg_primary_wus2.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.2.0/24"]
      }
    }
  }
}
resource "azapi_resource" "snet_westus2" {
  name      = "snet-${azapi_resource.rg_primary_wus2.location}"
  parent_id = azapi_resource.vnet_westus2.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.2.0/24"
    }
  }
}
resource "azapi_resource" "vnet_westus3" {
  location  = azapi_resource.rg_primary_wus3.location
  name      = "vnet-${azapi_resource.rg_primary_wus3.location}"
  parent_id = azapi_resource.rg_primary_wus3.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.3.0/24"]
      }
    }
  }
}
resource "azapi_resource" "snet_westus3" {
  name      = "snet-${azapi_resource.rg_primary_wus3.location}"
  parent_id = azapi_resource.vnet_westus3.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.3.0/24"
    }
  }
}

resource "azapi_resource" "vnet_eastus1" {
  location  = azapi_resource.rg_secondary_eus.location
  name      = "vnet-${azapi_resource.rg_secondary_eus.location}"
  parent_id = azapi_resource.rg_secondary_eus.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.11.0/24"]
      }
    }
  }
}
resource "azapi_resource" "snet_eastus1" {
  name      = "snet-${azapi_resource.rg_secondary_eus.location}"
  parent_id = azapi_resource.vnet_eastus1.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.11.0/24"
    }
  }
}
resource "azapi_resource" "vnet_eastus2" {
  location  = azapi_resource.rg_secondary_eus2.location
  name      = "vnet-${azapi_resource.rg_secondary_eus2.location}"
  parent_id = azapi_resource.rg_secondary_eus2.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.33.0/24"]
      }
    }
  }
}
resource "azapi_resource" "snet_eastus2" {
  name      = "snet-${azapi_resource.rg_secondary_eus2.location}"
  parent_id = azapi_resource.vnet_eastus2.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.33.0/24"
    }
  }
}
resource "azapi_resource" "vnet_centralus" {
  location  = azapi_resource.rg_secondary_cus.location
  name      = "vnet-${azapi_resource.rg_secondary_cus.location}"
  parent_id = azapi_resource.rg_secondary_cus.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.22.0/24"]
      }
    }
  }
}
resource "azapi_resource" "snet_centralus" {
  name      = "snet-${azapi_resource.rg_secondary_cus.location}"
  parent_id = azapi_resource.vnet_centralus.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.22.0/24"
    }
  }
}
