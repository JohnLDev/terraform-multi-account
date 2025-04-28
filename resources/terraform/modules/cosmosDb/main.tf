data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "random_password" "cosmosdb_admin_password" {
  length  = 16
  special = true
}

# Store the admin password in the Key Vault
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "cosmosdb-admin-password"
  value        = random_password.cosmosdb_admin_password.result
  key_vault_id = var.vault_id
}


resource "azurerm_cosmosdb_postgresql_cluster" "cosmos_db" {
  name                                 = "modular-tf-cosmosdb-${var.stage}"
  resource_group_name                  = data.azurerm_resource_group.rg.name
  location                             = data.azurerm_resource_group.rg.location
  administrator_login_password         = azurerm_key_vault_secret.admin_password.value
  coordinator_server_edition           = "BurstableMemoryOptimized"
  coordinator_public_ip_access_enabled = false
  coordinator_storage_quota_in_mb      = 32768
  coordinator_vcore_count              = 1
  node_count                           = 0
  node_public_ip_access_enabled        = false
  tags = {
    environment = var.stage
  }
}

resource "azurerm_subnet" "cosmosdb_subnet" {
  name                 = "cosmosdb-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.4.0/24"]
}


resource "azurerm_private_endpoint" "cosmos_pe" {
  name                = "pe-cosmosdb-${var.stage}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cosmosdb_subnet.id

  private_service_connection {
    name                           = "psc-cosmos-${var.stage}"
    private_connection_resource_id = azurerm_cosmosdb_postgresql_cluster.cosmos_db.id
    subresource_names              = ["coordinator"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.cosmos.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "dnslink-${var.stage}"
  resource_group_name   = data.azurerm_resource_group.rg.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
}

resource "azurerm_private_dns_a_record" "pe_record" {
  name                = azurerm_cosmosdb_postgresql_cluster.cosmos_db.name
  zone_name           = azurerm_private_dns_zone.postgresql.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.cosmos_pe.private_service_connection[0].private_ip_address]
}
