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


module "function_app" {
  source                     = "../modules/functionApp"
  rg_name                    = azurerm_resource_group.rg_group.name
  location                   = azurerm_resource_group.rg_group.location
  stage                      = var.stage
  storage_account_name       = module.storage_account.storage_account_name
  storage_account_access_key = module.storage_account.storage_account_access_key
  app_service_plan_name      = "modular-tf-service-plan"
  app_insights_name          = "modular-tf-appinsights"
  function_app_name          = "modular-tf-function-app"
  service_plan_sku           = "Y1"
}


