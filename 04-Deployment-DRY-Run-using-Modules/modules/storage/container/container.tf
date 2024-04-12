variable "storage_account_name" {
  type = string
}
variable "container_types" {
  type = list
}
variable "container_prefix" {
  type = string
}


resource "azurerm_storage_container" "container" {
  for_each              = toset(var.container_types)
  name                  = "${var.container_prefix}-${each.key}"
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}