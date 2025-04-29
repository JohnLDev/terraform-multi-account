output "vault_id" {
  value = azurerm_key_vault.vault_key.id
}

output "vault_name" {
  value = azurerm_key_vault.vault_key.name
}
