resource "azurerm_storage_account" "example" {
  name                     = "${var.name}${var.stage}"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  blob_properties {
    delete_retention_policy {
      permanent_delete_enabled = true
      days                     = 30
    }
  }
  tags = {
    environment = var.stage
  }
}
