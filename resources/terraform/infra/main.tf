resource "azurerm_resource_group" "rg_group" {
  name     = "modular-terraform-rg-${var.stage}"
  location = var.location
  tags = {
    environment = var.stage
  }
}

module "storage_account" {
  source   = "../modules/storageAccount"
  name     = "modulestorage"
  rg_name  = azurerm_resource_group.rg_group.name
  location = azurerm_resource_group.rg_group.location
  stage    = var.stage
}

resource "azurerm_storage_container" "main_blob_storage" {
  name                  = "modular-tf-container-blob-${var.stage}"
  storage_account_id    = module.storage_account.storage_account_id
  container_access_type = "private"
}

module "vnet" {
  source  = "../modules/vnet"
  name    = "modular-tf-vnet"
  rg_name = azurerm_resource_group.rg_group.name
  stage   = var.stage
}

module "function_app" {
  source                = "../modules/functionApp"
  rg_name               = azurerm_resource_group.rg_group.name
  location              = azurerm_resource_group.rg_group.location
  stage                 = var.stage
  storage_account_name  = module.storage_account.storage_account_name
  app_service_plan_name = "modular-tf-service-plan"
  app_insights_name     = "modular-tf-appinsights"
  function_app_name     = "modular-tf-function-app"
  service_plan_sku      = "FC1"
  subnet_id             = module.vnet.public_subnet_ids[1]
}

module "dns" {
  source  = "../modules/dns"
  stage   = var.stage
  rg_name = azurerm_resource_group.rg_group.name

}

module "key_vault" {
  source  = "../modules/keyVault"
  stage   = var.stage
  rg_name = azurerm_resource_group.rg_group.name
}

module "bastion_host" {
  source               = "../modules/bastionHost"
  rg_name              = azurerm_resource_group.rg_group.name
  stage                = var.stage
  vault_id             = module.key_vault.vault_id
  subnet_id            = module.vnet.public_subnet_ids[0]
  blob_storage_name    = azurerm_storage_container.main_blob_storage.name
  storage_account_name = module.storage_account.storage_account_name
  domain_zone_name     = module.dns.domain_zone_name
}
