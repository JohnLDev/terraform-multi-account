output "app_service_plan_id" {
  value = azurerm_service_plan.service_plan.id
}

output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}
