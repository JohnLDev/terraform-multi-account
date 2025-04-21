
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

resource "azurerm_dns_zone" "main_dns_zone" {
  name                = "${var.stage}.lubyjl.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}


resource "azurerm_dns_cname_record" "apim_cname" {
  name                = "api"
  zone_name           = azurerm_dns_zone.main_dns_zone.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 3600
  record              = "modular-tf-function-app-dev.azurewebsites.net"
}

# example of creation of new custom domain for static web app
# resource "azurerm_static_web_app_custom_domain" "example" {
#   static_web_app_id = azurerm_static_web_app.example.id
#   domain_name       = "${azurerm_dns_cname_record.example.name}.${azurerm_dns_cname_record.example.zone_name}"
#   validation_type   = "cname-delegation"
# }
