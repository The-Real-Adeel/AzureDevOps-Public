########
# Data #
########
data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "terraform-rg" {
  name = "terraform"
}

#############
# Resources #
#############

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.env}-${local.locShort}-phoenix-${local.suffix}" # geneate name by using the values stored in env, location short and suffix locals
  location = local.location                          # set location using a location local variable
  tags     = local.common_tags                       # set tags using tag local variable which is a map of resources
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.env}-${local.locShort}-phoenix-${local.suffix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.address_space]
  tags = merge(
    local.common_tags,
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
  name                 = "subnet-${var.env}-phoenix-${format("%03d", count.index + 1)}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [
    "${split(".", local.address_space)[0]}.${split(".", local.address_space)[1]}.${count.index + 1}.0/24"
  ]
}

resource "azurerm_network_security_group" "appnsg" {
  name                = "nsg-${var.env}-${local.locShort}-phoenix-${local.suffix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
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
  tags = azurerm_virtual_network.vnet.tags
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                     = var.subnet_count
  subnet_id                 = azurerm_subnet.subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.appnsg.id
}


resource "azurerm_storage_account" "storage" {
  name                            = lower(replace(replace(azurerm_resource_group.rg.name, "-", ""), "rg", "stracct"))
  location                        = local.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = local.account_replication_type
  default_to_oauth_authentication = true
  is_hns_enabled                  = true
  tags                            = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}

resource "azurerm_storage_container" "container" {
  for_each              = toset(local.containerTypes)
  name                  = "container-${var.env}-${each.key}"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "log-workspace" {
  count               = var.env == "prod" ? 1 : 0
  name                = "log-workspace-${var.env}-${local.locShort}-phoenix-${local.suffix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}

resource "azurerm_log_analytics_storage_insights" "example" {
  count               = var.env == "prod" ? 1 : 0
  name                = "log-storageinsightconfig-${var.env}-${local.locShort}-phoenix-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.log-workspace[count.index].id
  storage_account_id  = azurerm_storage_account.storage.id
  storage_account_key = azurerm_storage_account.storage.primary_access_key
}