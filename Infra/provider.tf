provider "azurerm" {

  features {

  }
}
# Configure the Azure provider

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.85.0"
    }
  }
}