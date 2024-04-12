# values passed in to the module
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "account_replication_type" {
  type = string
}
variable "tags" {
    type = map
}

# Resource created based on variables
resource "azurerm_storage_account" "storage" {
  name                            = lower(replace(replace(var.resource_group_name, "-", ""), "rg", "stracct"))
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = var.account_replication_type 
  default_to_oauth_authentication = true
  is_hns_enabled                  = true
  tags                            = var.tags
  lifecycle {
    ignore_changes = [
      tags["Date Created"],
    ]
  }
}

# The value we want returned to be used elsewhere in the parent
output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}