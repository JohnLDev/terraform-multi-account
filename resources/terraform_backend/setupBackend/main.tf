variable "location" {
  default = "East US"
}

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.26.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "be805c49-b92e-4ac0-ac32-942fdde7037b"
}


resource "azurerm_resource_group" "tf_rg" {
  name     = "tf-state-rg"
  location = var.location
}

resource "azurerm_storage_account" "tf_sa" {
  name                     = "johntfstatesa"
  resource_group_name      = azurerm_resource_group.tf_rg.name
  location                 = azurerm_resource_group.tf_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  blob_properties {
    delete_retention_policy {
      permanent_delete_enabled = true
      days                     = 30
    }
  }
}

resource "azurerm_storage_container" "backend" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tf_sa.id
  container_access_type = "private"
}
