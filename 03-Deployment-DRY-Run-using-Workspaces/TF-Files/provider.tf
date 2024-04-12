terraform { //throw in the provider version and source: found at: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs, click use provider to get latest info
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" { # the rest of the values will be injected from elsewhere (pipeline or local run)
    use_azuread_auth = true
  }
}

# We will use federated managed identity
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  use_oidc        = var.use_oidc
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    use_azuread_auth = true
  }
}
