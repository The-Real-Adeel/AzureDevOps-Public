terraform { //throw in the provider version and source: found at: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs, click use provider to get latest info
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" { # the rest of the values will be injected from elsewhere (pipeline or local run)
    use_azuread_auth     = true
  }
}

provider "azurerm" { //select the provider in our case its Azure
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.use_service_principal ? var.client_id : null
  client_secret   = var.use_service_principal ? var.client_secret : null
  features {}
}