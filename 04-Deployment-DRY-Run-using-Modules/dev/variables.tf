variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "create_storage_account" {
  type = bool
  default     = true
}

variable "create_virtual_network" {
  type = bool
  default     = true
}

variable "location" {
  type    = string
  default = "Canada Central"
  validation {
    condition = anytrue([
      var.location == "Canada Central" || var.location == "CanadaCentral" || var.location == "canada central" || var.location == "canadacentral",
      var.location == "Canada East" || var.location == "CanadaEast" || var.location == "canada east" || var.location == "canadaeast"
    ])
    error_message = "Please pick either Canada Central or Canada East."
  }
}

variable "use_oidc" {
  description = "The Pipeline will set this to true, otherwise you are connecting using AzureAD which requires this to be false"
  type        = bool
  default     = false
}

variable "env" {
  type        = string
  default     = "dev"
}

variable "resource_suffix" {
  type    = number
  default = 1
}

variable "subnet_count" {
  type    = number
  default = 3
  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 3
    error_message = "The count must be between 1 and 3."
  }
}