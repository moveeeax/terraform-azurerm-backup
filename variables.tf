variable "name" {
  description = "Name of the recovery services vault."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the vault."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the vault."
  type        = string
}

variable "sku" {
  description = "SKU of the recovery services vault. One of Standard or RS0."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "RS0"], var.sku)
    error_message = "The sku must be one of Standard or RS0."
  }
}

variable "soft_delete_enabled" {
  description = "Whether soft delete is enabled for the vault."
  type        = bool
  default     = true
}

variable "vm_backup_policy" {
  description = "Optional VM backup policy to create in the vault. Null disables policy creation."
  type = object({
    name                           = string
    timezone                       = optional(string, "UTC")
    backup_frequency               = optional(string, "Daily")
    backup_time                    = optional(string, "23:00")
    retention_daily_count          = optional(number, 7)
    instant_restore_retention_days = optional(number, 2)
  })
  default = null
}

variable "tags" {
  description = "Map of tags applied to the vault."
  type        = map(string)
  default     = {}
}
