##########
# Locals #
##########
locals {
  location          = var.location
  locationShortForm = var.location == "Canada Central" || var.location == "CanadaCentral" || var.location == "canada central" || var.location == "canadacentral" ? "cc" : var.location == "Canada East" || var.location == "CanadaEast" || var.location == "canada east" || var.location == "canadaeast" ? "ce" : "NA"
  common_tags = {
    "Creator"       = "Terraform"
    "Cost Centre"   = "0188"
    "Date Created"  = formatdate("YYYY-MM-DD'T'hh:mm:ss.'0000000'Z", timestamp()) # Seperate from modified as this will be set to ignore changes meta argument later
    "Date Modified" = formatdate("YYYY-MM-DD'T'hh:mm:ss.'0000000'Z", timestamp())
    "Project"       = "Phoenix Project"
    "Environment"   = "${var.env == "dev" ? "Development" : var.env == "prod" ? "Production" : "Invalid"}"
  }
  suffix                   = format("%03d", var.resource_suffix)
  general = { # map it to make it easier to transport between modules and reference these same values each time
    location = local.location
    short = local.locationShortForm
    suffix = local.suffix
    env = var.env
  }
  containerTypes           = ["general", "supporting", "index"]
  account_replication_type = var.env == "dev" ? "LRS" : var.env == "prod" ? "GRS" : "Invalid"
}

#############
# Resources #
#############
# We can create things at the root config file (also known as parent module)
# Note how we are using general local, this is easy to pass in the module later as a varaible map 
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.general.env}-${local.general.short}-phoenix-${local.general.suffix}"
  location = local.general.location                          
  tags     = local.common_tags                       
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}
########################################
# Example One: Module's within modules #
########################################
# In this example, we will showcase how to work with child modules and have child modules of those child modules. 
# You can theoratically go as deep in the family tree as you like but to reduce complexity keep it to a bare minimum (1, maybe 2 layers deep)
# The child module(vnet)'s child module(nsg) is in its own folder within vnet

module "network" {
  count = (var.create_virtual_network == true)? 1 : 0 # set whether to create or not based on variable
  source = "../modules/network" # reference where the module config files are
  general = local.general
  resource_group_name = azurerm_resource_group.rg.name
  tags = local.common_tags
  subnet_count = var.subnet_count
}

# this is the name taken from the nsg module that sits inside the network module.
# Notice how both the child modules output is not outputted during run, its only this one. 
output "nsg_id_that_shows_up_as_output" {
  value = module.network[0].nsg_id
}
# list of subnets created we will use for the next resource
output "subnet_details" {
  value = module.network[0].subnet_details
}

# while the following resource could have been deployed from the child module, I want to showcase how data taken from the child can be used to create things here
# While there is no reason to include subnet names from the module's output, just wanted to show you that you can pass through multiple variables using a map.
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                     = length(module.network[0].subnet_details)
  subnet_id                 = module.network[0].subnet_details[count.index].id # taken from network module
  network_security_group_id = module.network[0].nsg_id # taken from nsg module that hoped the data to network module
}


# As a way to showcase, how data traverses between modules especially in this two layer one. What if we want the output from the child's child module to work with here??
# General Rule: Things go in as variables to be used in the child module & things come out as outputs to be used in the parent module.check "name" {


####################################################################
# Example Two: Modules referencing other modules not child modules #
####################################################################
# in this example, working with modules for storage account where the module can refer another module container later using first modules data

# (ie the name produced in storage account module is used in the container module)

module "storage_account" {
  count = (var.create_storage_account == true)? 1 : 0
  source = "../modules/storage/storageaccount"
  location = local.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_replication_type        = local.account_replication_type
  tags                            = local.common_tags
}

# The following module to create containers will ingest the output taken from the previous module for storage account name (implying dependency)
# Note: These will not show up as references from the parent module directly unless you add outputs in the child and then reference that output here

module "container" {
  count = (var.create_storage_account == true)? 1 : 0
  source = "../modules/storage/container"
  container_prefix  = "container-${var.env}"
  container_types = local.containerTypes
  storage_account_name  = module.storage_account[0].storage_account_name  # output taken from child module storage account. [0] is needed as we added a count for true/false using count in that module
}
