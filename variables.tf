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
  description = <<-EOT
    Deprecated, kept so existing callers that pass `true` keep working. azurerm
    5.0 removed soft_delete_enabled from azurerm_recovery_services_vault, so the
    module no longer sets it: soft delete stays at the Azure/provider default
    (enabled, deleted backup items are retained for 14 days). Only true is
    accepted; disabling soft delete is no longer possible through this module.
  EOT
  type        = bool
  default     = true

  validation {
    condition     = var.soft_delete_enabled
    error_message = "soft_delete_enabled = false is no longer supported: azurerm 5.0 removed the argument. Soft delete stays enabled; disable it in the vault's security settings outside Terraform if you really need to."
  }
}

variable "storage_mode_type" {
  description = "Storage redundancy used for the vault's backup data. One of GeoRedundant, LocallyRedundant or ZoneRedundant. GeoRedundant is the Azure default and the only value that supports cross region restore."
  type        = string
  default     = "GeoRedundant"

  validation {
    condition     = contains(["GeoRedundant", "LocallyRedundant", "ZoneRedundant"], var.storage_mode_type)
    error_message = "The storage_mode_type must be one of GeoRedundant, LocallyRedundant or ZoneRedundant."
  }
}

variable "cross_region_restore_enabled" {
  description = "Whether cross region restore is enabled for the vault. Requires storage_mode_type to be GeoRedundant. Defaults to false, matching the Azure default, because cross region restore carries additional cost."
  type        = bool
  default     = false
}

variable "vm_backup_policy" {
  description = <<-EOT
    Optional VM backup policy to create in the vault. Null disables policy creation.

    Fields:
      name                           - Name of the backup policy.
      timezone                       - Timezone the schedule is evaluated in.
      backup_frequency               - "Daily" or "Weekly".
      backup_time                    - Schedule time as HH:MM; Azure only accepts :00 or :30.
      backup_weekdays                - Days to back up on. Required when backup_frequency is "Weekly".
      retention_daily_count          - Daily recovery points to keep. Used when backup_frequency is "Daily"; Azure requires 7-9999.
      retention_weekly_count         - Weekly recovery points to keep. Used when backup_frequency is "Weekly"; Azure requires 1-5163.
      instant_restore_retention_days - Instant restore snapshot retention; Azure requires 1-5 for this policy type.
  EOT

  type = object({
    name                           = string
    timezone                       = optional(string, "UTC")
    backup_frequency               = optional(string, "Daily")
    backup_time                    = optional(string, "23:00")
    backup_weekdays                = optional(list(string), [])
    retention_daily_count          = optional(number, 7)
    retention_weekly_count         = optional(number, 4)
    instant_restore_retention_days = optional(number, 2)
  })
  default = null

  validation {
    condition = var.vm_backup_policy == null ? true : contains(
      ["Daily", "Weekly"], var.vm_backup_policy.backup_frequency
    )
    error_message = "vm_backup_policy.backup_frequency must be one of Daily or Weekly."
  }

  validation {
    condition = var.vm_backup_policy == null ? true : can(
      regex("^([01][0-9]|2[0-3]):(00|30)$", var.vm_backup_policy.backup_time)
    )
    error_message = "vm_backup_policy.backup_time must be HH:MM in 24-hour form and land on a half hour (for example 02:00 or 02:30)."
  }

  validation {
    condition = var.vm_backup_policy == null ? true : (
      var.vm_backup_policy.backup_frequency != "Weekly" ||
      length(var.vm_backup_policy.backup_weekdays) > 0
    )
    error_message = "vm_backup_policy.backup_weekdays must list at least one day when backup_frequency is Weekly, otherwise Azure rejects the policy."
  }

  validation {
    condition = var.vm_backup_policy == null ? true : alltrue([
      for day in var.vm_backup_policy.backup_weekdays :
      contains(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], day)
    ])
    error_message = "vm_backup_policy.backup_weekdays entries must be full English day names, for example Sunday."
  }

  validation {
    condition = var.vm_backup_policy == null ? true : (
      var.vm_backup_policy.backup_frequency != "Daily" || (
        var.vm_backup_policy.retention_daily_count >= 7 &&
        var.vm_backup_policy.retention_daily_count <= 9999
      )
    )
    error_message = "vm_backup_policy.retention_daily_count must be between 7 and 9999 for a Daily policy. A lower value is rejected by Azure and a policy that retains nothing protects nothing."
  }

  validation {
    condition = var.vm_backup_policy == null ? true : (
      var.vm_backup_policy.backup_frequency != "Weekly" || (
        var.vm_backup_policy.retention_weekly_count >= 1 &&
        var.vm_backup_policy.retention_weekly_count <= 5163
      )
    )
    error_message = "vm_backup_policy.retention_weekly_count must be between 1 and 5163 for a Weekly policy."
  }

  validation {
    condition = var.vm_backup_policy == null ? true : (
      var.vm_backup_policy.instant_restore_retention_days >= 1 &&
      var.vm_backup_policy.instant_restore_retention_days <= 5
    )
    error_message = "vm_backup_policy.instant_restore_retention_days must be between 1 and 5."
  }
}

variable "tags" {
  description = "Map of tags applied to the vault."
  type        = map(string)
  default     = {}
}
