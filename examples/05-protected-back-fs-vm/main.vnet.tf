resource "azapi_resource" "virtual_network_westus1" {
  location  = azapi_resource.resource_group_primary_wus1.location
  name      = "vnet-${azapi_resource.resource_group_primary_wus1.location}"
  parent_id = azapi_resource.resource_group_primary_wus1.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.1.0/24"]
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_westus1" {
  name      = "snet-${azapi_resource.resource_group_primary_wus1.location}"
  parent_id = azapi_resource.virtual_network_westus1.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.1.0/24"
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_westus2" {
  location  = azapi_resource.resource_group_primary_wus2.location
  name      = "vnet-${azapi_resource.resource_group_primary_wus2.location}"
  parent_id = azapi_resource.resource_group_primary_wus2.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.2.0/24"]
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_westus2" {
  name      = "snet-${azapi_resource.resource_group_primary_wus2.location}"
  parent_id = azapi_resource.virtual_network_westus2.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.2.0/24"
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_westus3" {
  location  = azapi_resource.resource_group_primary_wus3.location
  name      = "vnet-${azapi_resource.resource_group_primary_wus3.location}"
  parent_id = azapi_resource.resource_group_primary_wus3.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.3.0/24"]
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_westus3" {
  name      = "snet-${azapi_resource.resource_group_primary_wus3.location}"
  parent_id = azapi_resource.virtual_network_westus3.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.3.0/24"
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_eastus1" {
  location  = azapi_resource.resource_group_secondary_eus.location
  name      = "vnet-${azapi_resource.resource_group_secondary_eus.location}"
  parent_id = azapi_resource.resource_group_secondary_eus.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.11.0/24"]
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_eastus1" {
  name      = "snet-${azapi_resource.resource_group_secondary_eus.location}"
  parent_id = azapi_resource.virtual_network_eastus1.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.11.0/24"
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_eastus2" {
  location  = azapi_resource.resource_group_secondary_eus2.location
  name      = "vnet-${azapi_resource.resource_group_secondary_eus2.location}"
  parent_id = azapi_resource.resource_group_secondary_eus2.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.33.0/24"]
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_eastus2" {
  name      = "snet-${azapi_resource.resource_group_secondary_eus2.location}"
  parent_id = azapi_resource.virtual_network_eastus2.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.33.0/24"
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "virtual_network_centralus" {
  location  = azapi_resource.resource_group_secondary_cus.location
  name      = "vnet-${azapi_resource.resource_group_secondary_cus.location}"
  parent_id = azapi_resource.resource_group_secondary_cus.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.22.0/24"]
      }
    }
  }
  response_export_values = ["*"]
}

resource "azapi_resource" "subnet_centralus" {
  name      = "snet-${azapi_resource.resource_group_secondary_cus.location}"
  parent_id = azapi_resource.virtual_network_centralus.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.22.0/24"
    }
  }
  response_export_values = ["*"]
}
