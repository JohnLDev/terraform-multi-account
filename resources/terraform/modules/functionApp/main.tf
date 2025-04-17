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

resource "azurerm_linux_function_app" "function_app" {
  name                = "${var.function_app_name}-${var.stage}"
  resource_group_name = var.rg_name
  location            = var.location

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  service_plan_id            = azurerm_service_plan.service_plan.id
  https_only                 = true


  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app_insights.connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.app_insights.instrumentation_key
  }

  site_config {
    application_insights_key               = azurerm_application_insights.app_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.app_insights.connection_string
    minimum_tls_version                    = "1.3"
    application_stack {
      node_version = 20
    }
  }
}
