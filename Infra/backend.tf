terraform {
  backend "azurerm" {
    resource_group_name  = "ACR-Test-RG"
    storage_account_name = "beenetstore"
    container_name       = "statefiles"
    key                  = "terraform.tfstate"
  }
}