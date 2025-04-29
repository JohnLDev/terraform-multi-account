data "azurerm_key_vault_secret" "admin_password" {
  name         = "cosmosdb-admin-password"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "admin_user" {
  name         = "cosmosdb-admin-user"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "cosmosdb_host" {
  name         = "cosmosdb-host"
  key_vault_id = var.key_vault_id
}
