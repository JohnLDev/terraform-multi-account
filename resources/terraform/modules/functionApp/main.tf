data "azurerm_storage_account" "storage_account" {
  name                = var.storage_account_name
  resource_group_name = var.rg_name
}



resource "azurerm_service_plan" "service_plan" {
  name                = "${var.app_service_plan_name}-${var.stage}"
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "${var.app_insights_name}-analytics-${var.stage}"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_application_insights" "app_insights" {
  name                = "${var.app_insights_name}-${var.stage}"
  location            = var.location
  resource_group_name = var.rg_name
  workspace_id        = azurerm_log_analytics_workspace.log_analytics.id
  application_type    = "web"
}

resource "azurerm_storage_container" "function_app_container" {
  name                  = "${var.function_app_name}-container-${var.stage}"
  storage_account_id    = data.azurerm_storage_account.storage_account.id
  container_access_type = "private"
}

resource "azurerm_function_app_flex_consumption" "function_app" {
  name                = "${var.function_app_name}-${var.stage}"
  resource_group_name = var.rg_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.service_plan.id


  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${data.azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.function_app_container.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = data.azurerm_storage_account.storage_account.primary_access_key
  runtime_name                = "node"
  runtime_version             = "20"
  maximum_instance_count      = 50
  instance_memory_in_mb       = 2048


  virtual_network_subnet_id = var.subnet_id


  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app_insights.connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.app_insights.instrumentation_key
    WEBSITE_VNET_ROUTE_ALL                = "1"
    PGDATABASE                            = "postgres"
    PGHOST                                = data.azurerm_key_vault_secret.cosmosdb_host.value
    PGUSER                                = data.azurerm_key_vault_secret.admin_user.value
    PGPASSWORD                            = data.azurerm_key_vault_secret.admin_password.value
    PGPORT                                = "5432"
  }

  site_config {
    application_insights_key               = azurerm_application_insights.app_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.app_insights.connection_string
    minimum_tls_version                    = "1.3"
  }
  lifecycle {
    ignore_changes = [
      app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      app_settings["APPLICATIONINSIGHTS_CONNECTION_STRING"]
    ]
  }
}
