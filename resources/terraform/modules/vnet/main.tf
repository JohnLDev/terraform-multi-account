# Azure Provider configuration block
variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# Data source for existing Resource Group
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

resource "azurerm_network_watcher" "example" {
  name                = "nwwatcher-${var.stage}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-${var.stage}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space

  tags = {
    Environment = var.stage
  }
}

# Public Subnets
resource "azurerm_subnet" "public" {
  count                = 2
  name                 = "public-subnet-${count.index + 1}"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, count.index)]

  dynamic "delegation" {
    for_each = count.index == 1 ? [1] : []
    content {
      name = "web-delegation-${count.index + 1}"
      service_delegation {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

# Private Subnets
resource "azurerm_subnet" "private" {
  count                = 2
  name                 = "private-subnet-${count.index + 1}"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, count.index + 2)]
}

# resource "azurerm_nat_gateway" "nat_gateway" {
#   name                = "modular-tf-nat-gateway-${var.stage}"
#   resource_group_name = data.azurerm_resource_group.rg.name
#   location            = data.azurerm_resource_group.rg.location
#   sku_name            = "Standard"
# }

# resource "azurerm_subnet_nat_gateway_association" "private" {
#   count          = 2
#   subnet_id      = azurerm_subnet.private[count.index].id
#   nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
# }

# Network Security Group for Public Subnets
resource "azurerm_network_security_group" "public" {
  name                = "public-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.stage
  }
}

# Network Security Group for Private Subnets
resource "azurerm_network_security_group" "private" {
  name                = "private-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.stage
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  count                     = 2
  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count                     = 2
  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private.id
}

# Route Table for Private Subnets
resource "azurerm_route_table" "private" {
  name                = "private-rt"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  route {
    name           = "local"
    address_prefix = var.vnet_address_space[0]
    next_hop_type  = "VnetLocal"
  }

  tags = {
    Environment = var.stage
  }
}

# Associate Route Table with Private Subnets
resource "azurerm_subnet_route_table_association" "private" {
  count          = 2
  subnet_id      = azurerm_subnet.private[count.index].id
  route_table_id = azurerm_route_table.private.id
}
