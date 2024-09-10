
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "d200e3b2-c0dc-4076-bd30-4ccccf05ffeb"
}