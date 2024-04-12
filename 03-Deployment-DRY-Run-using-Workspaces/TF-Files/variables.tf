locals {
  location          = var.location
  locShort = var.location == "Canada Central" || var.location == "CanadaCentral" || var.location == "canada central" || var.location == "canadacentral" ? "cc" : var.location == "Canada East" || var.location == "CanadaEast" || var.location == "canada east" || var.location == "canadaeast" ? "ce" : "NA"
  common_tags = {
    "Creator"       = "Terraform"
    "Cost Centre"   = "0188"
    "Date Modified" = formatdate("YYYY-MM-DD'T'hh:mm:ss.'0000000'Z", timestamp())
    "Date Created"  = formatdate("YYYY-MM-DD'T'hh:mm:ss.'0000000'Z", timestamp())
    "Project"       = "Phoenix Project"
    "Environment"   = "${var.env == "dev" ? "Development" : var.env == "prod" ? "Production" : "Invalid"}"
  }
  address_space            = var.env == "prod" ? "10.50.0.0/16" : var.env == "dev" ? "10.51.0.0/16" : "Invalid"
  containerTypes           = ["general", "supporting", "index"]
  account_replication_type = var.env == "dev" ? "LRS" : var.env == "prod" ? "GRS" : "Invalid"
  suffix                   = format("%03d", var.resource_suffix)
  networksecuritgroup_rules = [
    {
      priority               = 200
      destination_port_range = "3389"
      access                 = "Allow"
      source_address_prefix  = "VirtualNetwork"
    },
    {
      priority               = 300
      destination_port_range = "80"
      access                 = "Deny"
    },
    {
      priority               = 100
      destination_port_range = "443"
    }
  ]
}

variable "subscription_id" {
  type = string
}


variable "tenant_id" {
  type = string
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
  description = "Two workspaces for this deployment exists, dev or prod. Based on them this values are set"
  type        = string
  default     = "dev"
  validation {
    condition = anytrue([
      var.env == "prod",
      var.env == "dev"
    ])
    error_message = "Must select environment: prod or dev."
  }
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