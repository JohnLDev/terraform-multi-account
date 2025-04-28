variable "rg_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "stage" {
  description = "value of stage"
  type        = string
  validation {
    condition     = contains(["dev", "sandbox", "prd"], var.stage)
    error_message = "Stage must be set to dev, sandbox, or prod."
  }
}

variable "vault_id" {
  description = "ID of the Key Vault to save the cosmos db password"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

