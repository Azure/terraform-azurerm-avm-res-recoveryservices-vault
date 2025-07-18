terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    # TODO: Ensure all required providers are listed here.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.107.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.1"
    }
  }
}
