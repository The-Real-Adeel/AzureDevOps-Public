##################
# Current Config #
##################
# Current Config for the deployment. 
data "azurerm_client_config" "current" {}

###################
# Resource Groups #
###################

# Resource Group where resources created will be stored
resource "azurerm_resource_group" "aks-rg" {
  name     = "aks-rg"
  location = local.locationCC
}
# Resource Group we will deploy crossplane resources to
resource "azurerm_resource_group" "rg_crossplane" {
  name     = "crossplaneRG"
  location = local.locationCC
}
##############
# Identities #
##############

# Identity for the cluster and kubelet, NOT to be used for deployments through crossplane this time
resource "azurerm_user_assigned_identity" "aks-managed-identity" {
  location            = local.locationCC
  name                = "aks-managed-identity"
  resource_group_name = azurerm_resource_group.aks-rg.name
}

# Workload Identity. The identity we will assign to the pod
resource "azurerm_user_assigned_identity" "aks-workload-network-identity" {
  location            = local.locationCC
  name                = "aks-workload-network-identity"
  resource_group_name = azurerm_resource_group.aks-rg.name
}
resource "azurerm_user_assigned_identity" "aks-workload-storage-identity" {
  location            = local.locationCC
  name                = "aks-workload-storage-identity"
  resource_group_name = azurerm_resource_group.aks-rg.name
}

# Forloop identities for picking which identities you want to be added to owners for crossplaneRG
locals {
  identities_crossplaneRG = {
    # aks-managed-identity  = azurerm_user_assigned_identity.aks-managed-identity.principal_id
    aks-workload-network-identity = azurerm_user_assigned_identity.aks-workload-network-identity.principal_id
    aks-workload-storage-identity = azurerm_user_assigned_identity.aks-workload-storage-identity.principal_id
  }
}

# apply ownership to identities in the foreach for reader
resource "azurerm_role_assignment" "reader" {
  for_each             = local.identities_crossplaneRG
  scope                = azurerm_resource_group.rg_crossplane.id
  role_definition_name = "reader"
  principal_id         = each.value
}
# apply network contributor to resource group for network managed identity
resource "azurerm_role_assignment" "network_contributor" {
  scope                = azurerm_resource_group.rg_crossplane.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-workload-network-identity.principal_id
}
# apply storage account contributor to resource group for storage managed identity
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_resource_group.rg_crossplane.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-workload-storage-identity.principal_id
}
########################################
# ACR Placeholder - Not used currently #
########################################

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "corporegistryAKS001"
  resource_group_name = azurerm_resource_group.aks-rg.name
  location            = local.locationCC
  sku                 = "Standard"
  admin_enabled       = false
}

# Assignment for cluster User Assigned Managed Identity for: it's kubelet identity role assignment
resource "azurerm_role_assignment" "managed_identity_operator" {
  scope                = azurerm_resource_group.aks-rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks-managed-identity.principal_id
}

# Assignment for cluster User Assigned Managed Identity for: ACR to AKS
resource "azurerm_role_assignment" "acrpull" {
  principal_id                     = azurerm_user_assigned_identity.aks-managed-identity.principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_resource_group.aks-rg.id
  skip_service_principal_aad_check = true
}

###############
# AKS CLUSTER #
###############

# Azure Kubernetes Service Cluster
resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = "corpo-aks-crossplane"
  location            = local.locationCC
  resource_group_name = azurerm_resource_group.aks-rg.name
  dns_prefix          = "corpoakscrossplane"

  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = "Standard_B2ms"
    enable_auto_scaling = false
  }
  identity { # This identity is of the control plane
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks-managed-identity.id]
  }
  kubelet_identity { # This identity set provides every node with this permission to do things. We will NOT use this this time
    client_id                 = azurerm_user_assigned_identity.aks-managed-identity.client_id
    object_id                 = azurerm_user_assigned_identity.aks-managed-identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks-managed-identity.id
  }
  # These next two are needed to be enabled for workload identities, which we will set in the namespaces later
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  depends_on = [azurerm_user_assigned_identity.aks-managed-identity, azurerm_role_assignment.managed_identity_operator]
  tags = {
    name = "test"
  }
}

###########
# Outputs #
###########
# Outputs we will store in a file to access later
# One way is to place it in a file: terraform output -json > outputs.json
# Or you can directly copy it into a variable with PS: $outputJSON = terraform output -json | ConvertFrom-Json

# Login Server URL
output "acr_login_server_url" {
  value = azurerm_container_registry.acr.login_server
}
# AKS Name 
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks-cluster.name
}
# AKS RG
output "resource_group_aks" {
  value = azurerm_resource_group.aks-rg
}
# Crossplane RG
output "resource_group_crossplane" {
  value = azurerm_resource_group.rg_crossplane
}
# URL for AKS ODIC
output "aks_odic_issuer_url" {
  value = azurerm_kubernetes_cluster.aks-cluster.oidc_issuer_url
}
# AKS Managed Identity
output "aks_managed_identity" {
  value = azurerm_user_assigned_identity.aks-managed-identity
}
# AKS Network Workload Identity
output "aks_workload_network_identity" {
  value = azurerm_user_assigned_identity.aks-workload-network-identity
}
# AKS Storage Workload Identity
output "aks_workload_storage_identity" {
  value = azurerm_user_assigned_identity.aks-workload-storage-identity
}
# Tenant ID
output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
# Subscription ID
output "sub_id" {
  value = data.azurerm_client_config.current.subscription_id
}

# This ID output is "/subscriptions/<subID>/resourceGroups/aks-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aks-workload-network-identity"
# output "aks-workload-network-identity_id" {
#   value = azurerm_user_assigned_identity.aks-workload-network-identity.id
# }