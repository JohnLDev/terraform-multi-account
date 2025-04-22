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
