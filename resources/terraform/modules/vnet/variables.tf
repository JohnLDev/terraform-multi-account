variable "stage" {
  description = "value of stage"
  type        = string
  validation {
    condition     = contains(["dev", "sandbox", "prd"], var.stage)
    error_message = "Stage must be set to dev, sandbox, or prod."
  }
}

variable "name" {
  type        = string
  description = "Name of the Azure Virtual Network"
}

variable "rg_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}
