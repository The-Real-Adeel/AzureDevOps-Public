# values passed in to the module
variable "resource_group_name" {
  type = string
}
variable "general" {
  type = map
}
variable "tags" {
  type = map
}
locals {              
  networksecuritgroup_rules = [
    {
      priority               = 200
      destination_port_range = "3389"
      access                 = "Allow"
      source_address_prefix  = "VirtualNetwork"
    },
    {
      priority               = 300
      destination_port_range = "80"
      access                 = "Deny"
    },
    {
      priority               = 100
      destination_port_range = "443"
    }
  ]
}

resource "azurerm_network_security_group" "appnsg" {
  name                = "nsg-${var.general.env}-${var.general.short}-phoenix-${var.general.suffix}"
  location            = var.general.location
  resource_group_name = var.resource_group_name
  dynamic "security_rule" {
    for_each = local.networksecuritgroup_rules
    content {
      name = "${lookup(security_rule.value, "access", "Allow")}-Port-${security_rule.value.destination_port_range}"
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = lookup(security_rule.value, "access", "Allow")
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", "*")
      destination_address_prefix = "*"
    }
  }
  tags = var.tags
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}

output "nsg_id" {
  value = resource.azurerm_network_security_group.appnsg.id
}