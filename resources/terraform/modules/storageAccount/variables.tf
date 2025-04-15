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
  description = "Name of the Azure Storage Account"

  validation {
    condition     = can(regex("^[a-z0-9]{3,17}$", var.name))
    error_message = "Storage account name must be 3–17 characters, using only lowercase letters and numbers."
  }
}

variable "rg_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Location of the Azure Resource Group"
}
