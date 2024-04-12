##########
# Config #
##########
data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}
data "azuredevops_project" "ado-project" {
  name = var.project_name
}

locals {
  azure_managed_identity_name = "ado-federated-ID"
  ado_service_account_name = "azure-federated-account"
  locationCC = "Canada Central"
}
resource "random_integer" "suffix-integer" {
  min = 10
  max = 99
  }

###################
# Resource Groups #
###################

data "azurerm_resource_group" "terraform-rg" {
  name = "terraform"
}

#############
# Resources #
#############

resource "azurerm_user_assigned_identity" "terraform-identity" {
  location            = local.locationCC
  name                = local.azure_managed_identity_name
  resource_group_name = data.azurerm_resource_group.terraform-rg.name
}

resource "azurerm_role_assignment" "subscription-assignment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "owner"
  principal_id         = azurerm_user_assigned_identity.terraform-identity.principal_id
}

resource "azurerm_federated_identity_credential" "federated_credential" {
  name                = "terraform-deployment-federated-credential"
  resource_group_name = data.azurerm_resource_group.terraform-rg.name
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.terraform-identity.id
  issuer              = azuredevops_serviceendpoint_azurerm.service_connection.workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.service_connection.workload_identity_federation_subject
}

# Create Registry for Phase 2
resource "azurerm_container_registry" "acr" {
  name                = "corpocontainerregistry${random_integer.suffix-integer.result}"
  resource_group_name = data.azurerm_resource_group.terraform-rg.name
  location            = local.locationCC
  sku                 = "Standard"
  admin_enabled       = true
}

# https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/serviceendpoint_azurerm
resource "azuredevops_serviceendpoint_azurerm" "service_connection" {
  project_id                             = data.azuredevops_project.ado-project.id
  service_endpoint_name                  = local.ado_service_account_name
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.terraform-identity.client_id
  }
  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.primary.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.primary.display_name
}