data "azurerm_resource_group" "rg" {
  name = var.rg_name
}
data "azurerm_client_config" "current" {}

# Define the Key Vault
resource "azurerm_key_vault" "vault_key" {
  name                = "modular-tf-keyvault-${var.stage}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_access_policy" "v_policy" {
  key_vault_id = azurerm_key_vault.vault_key.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  storage_permissions = [
    "Get",
    "List",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",  # Permission to retrieve secrets
    "List", # Permission to list secrets in the Key Vault
    "Set",
  ]
}

# Generate a random password
resource "random_password" "bastion_admin_password" {
  length  = 16
  special = true
}

# Store the admin password in the Key Vault
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "bastion-host-password"
  value        = random_password.bastion_admin_password.result
  key_vault_id = azurerm_key_vault.vault_key.id
}
