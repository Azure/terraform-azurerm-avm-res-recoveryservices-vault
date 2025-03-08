
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "6284f04c-ec26-45e3-a7a6-24c2ef4722e4"
}