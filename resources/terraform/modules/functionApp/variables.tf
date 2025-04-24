variable "stage" {
  description = "value of stage"
  type        = string
  validation {
    condition     = contains(["dev", "sandbox", "prd"], var.stage)
    error_message = "Stage must be set to dev, sandbox, or prod."
  }
}

variable "rg_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  type        = string
  description = "Location of the Azure Resource Group"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "service_plan_sku" {
  description = "The SKU of the App Service Plan (e.g., Y1, B1, S1, P1v2, EP1, etc.)"
  type        = string
  default     = "Y1"

  validation {
    condition = contains([
      "F1", "D1",             # Free/Shared
      "FC1",                  # Function Consumption
      "B1", "B2", "B3",       # Basic
      "S1", "S2", "S3",       # Standard
      "P1v2", "P2v2", "P3v2", # Premium v2
      "P1v3", "P2v3", "P3v3", # Premium v3
      "EP1", "EP2", "EP3",    # Elastic Premium (Functions)
      "Y1",                   # Consumption (Functions)
      "I1", "I2", "I3"        # Isolated
    ], var.service_plan_sku)
    error_message = "Invalid App Service Plan SKU. Must be one of: F1, D1, B1–B3, S1–S3, P1v2–P3v2, P1v3–P3v3, EP1–EP3, Y1, I1–I3."
  }
}
variable "app_insights_name" {
  description = "Name of the Application Insights"
  type        = string
}

variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Storage Account"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}
