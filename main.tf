resource "azurerm_recovery_services_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  soft_delete_enabled = var.soft_delete_enabled

  storage_mode_type            = var.storage_mode_type
  cross_region_restore_enabled = var.cross_region_restore_enabled

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !var.cross_region_restore_enabled || var.storage_mode_type == "GeoRedundant"
      error_message = "cross_region_restore_enabled requires storage_mode_type to be GeoRedundant."
    }
  }
}

resource "azurerm_backup_policy_vm" "this" {
  count = var.vm_backup_policy == null ? 0 : 1

  name                           = var.vm_backup_policy.name
  resource_group_name            = var.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.this.name
  timezone                       = var.vm_backup_policy.timezone
  instant_restore_retention_days = var.vm_backup_policy.instant_restore_retention_days

  backup {
    frequency = var.vm_backup_policy.backup_frequency
    time      = var.vm_backup_policy.backup_time

    # Azure requires the schedule to name the days it runs on for a weekly
    # policy, and rejects weekdays on a daily one.
    weekdays = var.vm_backup_policy.backup_frequency == "Weekly" ? var.vm_backup_policy.backup_weekdays : null
  }

  # Azure pairs each backup frequency with a matching retention block: a daily
  # schedule must carry retention_daily and a weekly schedule retention_weekly.
  # Emitting the wrong one produces a policy the service refuses to create.
  dynamic "retention_daily" {
    for_each = var.vm_backup_policy.backup_frequency == "Daily" ? [1] : []

    content {
      count = var.vm_backup_policy.retention_daily_count
    }
  }

  dynamic "retention_weekly" {
    for_each = var.vm_backup_policy.backup_frequency == "Weekly" ? [1] : []

    content {
      count    = var.vm_backup_policy.retention_weekly_count
      weekdays = var.vm_backup_policy.backup_weekdays
    }
  }
}
