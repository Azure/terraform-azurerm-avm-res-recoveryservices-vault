resource "azurerm_virtual_network" "westus1" {
  location            = azurerm_resource_group.primary_wus1.location
  name                = "vnet-${azurerm_resource_group.primary_wus1.location}"
  resource_group_name = azurerm_resource_group.primary_wus1.name
  address_space       = ["192.168.1.0/24"]
}
# output "vnet" {
#   value = azurerm_virtual_network.westus1
# }
resource "azurerm_subnet" "westus1" {
  address_prefixes     = ["192.168.1.0/24"]
  name                 = "snet-${azurerm_resource_group.primary_wus1.location}"
  resource_group_name  = azurerm_resource_group.primary_wus1.name
  virtual_network_name = azurerm_virtual_network.westus1.name
}
resource "azurerm_virtual_network" "westus2" {
  location            = azurerm_resource_group.primary_wus2.location
  name                = "vnet-${azurerm_resource_group.primary_wus2.location}"
  resource_group_name = azurerm_resource_group.primary_wus2.name
  address_space       = ["192.168.2.0/24"]
}
resource "azurerm_subnet" "westus2" {
  address_prefixes     = ["192.168.2.0/24"]
  name                 = "snet-${azurerm_resource_group.primary_wus2.location}"
  resource_group_name  = azurerm_resource_group.primary_wus2.name
  virtual_network_name = azurerm_virtual_network.westus2.name
}
resource "azurerm_virtual_network" "westus3" {
  location            = azurerm_resource_group.primary_wus3.location
  name                = "vnet-${azurerm_resource_group.primary_wus3.location}"
  resource_group_name = azurerm_resource_group.primary_wus3.name
  address_space       = ["192.168.3.0/24"]
}
resource "azurerm_subnet" "westus3" {
  address_prefixes     = ["192.168.3.0/24"]
  name                 = "snet-${azurerm_resource_group.primary_wus3.location}"
  resource_group_name  = azurerm_resource_group.primary_wus3.name
  virtual_network_name = azurerm_virtual_network.westus3.name
}

resource "azurerm_virtual_network" "eastus1" {
  location            = azurerm_resource_group.secondary_eus.location
  name                = "vnet-${azurerm_resource_group.secondary_eus.location}"
  resource_group_name = azurerm_resource_group.secondary_eus.name
  address_space       = ["192.168.11.0/24"]
}
resource "azurerm_subnet" "eastus1" {
  address_prefixes     = ["192.168.11.0/24"]
  name                 = "snet-${azurerm_resource_group.secondary_eus.location}"
  resource_group_name  = azurerm_resource_group.secondary_eus.name
  virtual_network_name = azurerm_virtual_network.eastus1.name
}
resource "azurerm_virtual_network" "eastus2" {
  location            = azurerm_resource_group.secondary_eus2.location
  name                = "vnet-${azurerm_resource_group.secondary_eus2.location}"
  resource_group_name = azurerm_resource_group.secondary_eus2.name
  address_space       = ["192.168.33.0/24"]
}
resource "azurerm_subnet" "eastus2" {
  address_prefixes     = ["192.168.33.0/24"]
  name                 = "snet-${azurerm_resource_group.secondary_eus2.location}"
  resource_group_name  = azurerm_resource_group.secondary_eus2.name
  virtual_network_name = azurerm_virtual_network.eastus2.name
}
resource "azurerm_virtual_network" "centralus" {
  location            = azurerm_resource_group.secondary_cus.location
  name                = "vnet-${azurerm_resource_group.secondary_cus.location}"
  resource_group_name = azurerm_resource_group.secondary_cus.name
  address_space       = ["192.168.22.0/24"]
}
resource "azurerm_subnet" "centralus" {
  address_prefixes     = ["192.168.22.0/24"]
  name                 = "snet-${azurerm_resource_group.secondary_cus.location}"
  resource_group_name  = azurerm_resource_group.secondary_cus.name
  virtual_network_name = azurerm_virtual_network.centralus.name
}

/*
resource "azurerm_virtual_network" "westus3" {
  name                = "network3"
  resource_group_name = azurerm_resource_group.primary_wus3.name
  address_space       = ["192.168.3.0/24"]
  location            = "westus3"
}
resource "azurerm_subnet" "westus3" {
  name                 = "network3-subnet"
  resource_group_name  = azurerm_resource_group.primary_wus3.name
  virtual_network_name = azurerm_virtual_network.westus3.name
  address_prefixes     = ["192.168.3.0/24"]
}
resource "azurerm_virtual_network" "eastus2" {
  name                = "network4"
  resource_group_name = azurerm_resource_group.secondary.name
  address_space       = ["192.168.4.0/24"]
  location            = "eastus2"
}
resource "azurerm_subnet" "eastus2" {
  name                 = "network4-subnet"
  resource_group_name  = azurerm_resource_group.secondary.name
  virtual_network_name = azurerm_virtual_network.eastus2.name
  address_prefixes     = ["192.168.4.0/24"]
}
*/