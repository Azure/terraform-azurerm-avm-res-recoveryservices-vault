terraform {
  required_version = ">= 1.9, < 2.0"

  backend "azurerm" {
    subscription_id      = "c5c1228d-b650-4f0a-97ea-1f8cfdc417c5"
    resource_group_name  = "rg-tfstate-shared"
    storage_account_name = "stb7q2znqmpox3hmix"
    container_name       = "tfstate"
    key                  = "default.tfstate"
  }

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.34.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

