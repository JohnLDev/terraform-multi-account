resource "azurerm_storage_account" "example" {
  name                     = "${var.name}${var.stage}"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags = {
    environment = var.stage
  }
}
