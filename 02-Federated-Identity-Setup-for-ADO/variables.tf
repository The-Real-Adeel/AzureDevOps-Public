########################
# AzureDevOps Provider #
########################
variable "site_url" {
  type = string
}

variable "project_name" {
  type = string
}

variable "personal_access_token" {
  type = string
}
####################
# AzureRM Provider #
####################
variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "client_secret" {
  type      = string
  sensitive = true
  default   = null
}

# if you want to use a service principal set to true... or az login set to false
variable "use_service_principal" {
  type        = bool
  description = "Tells the Terraform provider to use service principal"
  default     = true
}