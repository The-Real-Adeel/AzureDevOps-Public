# Values passed in to the module
variable "resource_group_name" {
  type = string
}
variable "general" {
  type = map
}
variable "tags" {
  type = map
}
variable "subnet_count" {
  type = number
}
locals {
  address_space = var.general.env == "prod" ? "10.50.0.0/16" : var.general.env == "dev" ? "10.51.0.0/16" : "Invalid"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.general.env}-${var.general.short}-phoenix-${var.general.suffix}"
  location            = var.general.location
  resource_group_name = var.resource_group_name
  address_space       = [local.address_space]
  tags = merge(
    var.tags,
    {
      "TeamAssigned" = "NetworkDepartment"
      "Cost Centre"  = "4001"
    }
  )
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}

resource "azurerm_subnet" "subnet" {
  count                = var.subnet_count
  name                 = "subnet-${var.general.env}-phoenix-${format("%03d", count.index + 1)}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [
    "${split(".", local.address_space)[0]}.${split(".", local.address_space)[1]}.${count.index + 1}.0/24"
  ]
}

# Example of a child module for this module we are insidecheck
# Our goal is to pass in data and take it back to parent where IT can use the data to build more things
# We dont need count of making it or not, as it's only going to create the following if the current module is being applied from the parent

module "nsg" {
  source = "./NSG"
  resource_group_name = var.resource_group_name # example of something from parent coming to this child and going further down in the child's child.
  general = var.general
  tags = azurerm_virtual_network.vnet.tags # since the vnet ingests more data, we are going to add it's instead
}

output "nsg_id" {
  value = module.nsg.nsg_id
}

# This resource can contain any number of subnets, we want the names of all so we store it as a list using [] and inject name value AND id in each subnet(s) using the for loop
output "subnet_details" {
  value = [for s in azurerm_subnet.subnet : { name = s.name, id = s.id }]
}