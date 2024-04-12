terraform { //throw in the provider version and source: found at: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs, click use provider to get latest info
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "=0.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" { # the rest of the values will be injected from elsewhere (pipeline or local run)
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.use_service_principal ? var.client_id : null
  client_secret   = var.use_service_principal ? var.client_secret : null
}

provider "azuredevops" {
  org_service_url = var.site_url
  personal_access_token = var.personal_access_token
}

