resource "azurerm_storage_container" "example" {
  name                  = "modular-tf-container-blob-${var.stage}"
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
}
