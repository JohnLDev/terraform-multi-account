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
  description = "ID of the Key Vault"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the bastion host will be deployed"
  type        = string
}

variable "blob_storage_name" {
  description = "Name of the blob storage"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "domain_zone_name" {
  description = "Name of the domain zone"
  type        = string
  nullable    = true
}
