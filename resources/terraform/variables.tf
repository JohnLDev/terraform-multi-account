variable "SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
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


variable "location" {
  type        = string
  description = "Location of the Azure Resource Group"
  default     = "eastus"
}
