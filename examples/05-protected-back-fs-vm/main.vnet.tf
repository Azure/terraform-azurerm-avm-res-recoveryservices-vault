resource "azurerm_virtual_network" "westus1" {
  name                = "vnet-${azurerm_resource_group.primary_wus1.location}"
  resource_group_name = azurerm_resource_group.primary_wus1.name
  address_space       = ["192.168.1.0/24"]
  location            = azurerm_resource_group.primary_wus1.location
}
# output "vnet" {
#   value = azurerm_virtual_network.westus1
# }
resource "azurerm_subnet" "westus1" {
  name                 = "snet-${azurerm_resource_group.primary_wus1.location}"
  resource_group_name  = azurerm_resource_group.primary_wus1.name
  virtual_network_name = azurerm_virtual_network.westus1.name
  address_prefixes     = ["192.168.1.0/24"]
}
resource "azurerm_virtual_network" "westus2" {
  name                = "vnet-${azurerm_resource_group.primary_wus2.location}"
  resource_group_name = azurerm_resource_group.primary_wus2.name
  address_space       = ["192.168.2.0/24"]
  location            = azurerm_resource_group.primary_wus2.location
}
resource "azurerm_subnet" "westus2" {
  name                 = "snet-${azurerm_resource_group.primary_wus2.location}"
  resource_group_name  = azurerm_resource_group.primary_wus2.name
  virtual_network_name = azurerm_virtual_network.westus2.name
  address_prefixes     = ["192.168.2.0/24"]
}
resource "azurerm_virtual_network" "westus3" {
  name                = "vnet-${azurerm_resource_group.primary_wus3.location}"
  resource_group_name = azurerm_resource_group.primary_wus3.name
  address_space       = ["192.168.3.0/24"]
  location            = azurerm_resource_group.primary_wus3.location
}
resource "azurerm_subnet" "westus3" {
  name                 = "snet-${azurerm_resource_group.primary_wus3.location}"
  resource_group_name  = azurerm_resource_group.primary_wus3.name
  virtual_network_name = azurerm_virtual_network.westus3.name
  address_prefixes     = ["192.168.3.0/24"]
}

resource "azurerm_virtual_network" "eastus1" {
  name                = "vnet-${azurerm_resource_group.secondary_eus.location}"
  resource_group_name = azurerm_resource_group.secondary_eus.name
  address_space       = ["192.168.11.0/24"]
  location            = azurerm_resource_group.secondary_eus.location
}
resource "azurerm_subnet" "eastus1" {
  name                 = "snet-${azurerm_resource_group.secondary_eus.location}"
  resource_group_name  = azurerm_resource_group.secondary_eus.name
  virtual_network_name = azurerm_virtual_network.eastus1.name
  address_prefixes     = ["192.168.11.0/24"]
}
resource "azurerm_virtual_network" "eastus2" {
  name                = "vnet-${azurerm_resource_group.secondary_eus2.location}"
  resource_group_name = azurerm_resource_group.secondary_eus2.name
  address_space       = ["192.168.33.0/24"]
  location            = azurerm_resource_group.secondary_eus2.location
}
resource "azurerm_subnet" "eastus2" {
  name                 = "snet-${azurerm_resource_group.secondary_eus2.location}"
  resource_group_name  = azurerm_resource_group.secondary_eus2.name
  virtual_network_name = azurerm_virtual_network.eastus2.name
  address_prefixes     = ["192.168.33.0/24"]
}
resource "azurerm_virtual_network" "centralus" {
  name                = "vnet-${azurerm_resource_group.secondary_cus.location}"
  resource_group_name = azurerm_resource_group.secondary_cus.name
  address_space       = ["192.168.22.0/24"]
  location            = azurerm_resource_group.secondary_cus.location
}
resource "azurerm_subnet" "centralus" {
  name                 = "snet-${azurerm_resource_group.secondary_cus.location}"
  resource_group_name  = azurerm_resource_group.secondary_cus.name
  virtual_network_name = azurerm_virtual_network.centralus.name
  address_prefixes     = ["192.168.22.0/24"]
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