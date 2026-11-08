resource "azurerm_recovery_services_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # soft_delete_enabled is not set: azurerm 5.0 removed the argument, and on
  # 3.x/4.x leaving it unset keeps the provider default (enabled). See
  # var.soft_delete_enabled.

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

# Enrols each VM in the module's VM backup policy. Keyed by the caller's map
# keys rather than by VM ID, so the keys must be known at plan time while the
# IDs themselves may come from resources created in the same apply.
resource "azurerm_backup_protected_vm" "this" {
  for_each = var.protected_vm_ids

  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  source_vm_id        = each.value
  backup_policy_id    = one(azurerm_backup_policy_vm.this[*].id)

  lifecycle {
    precondition {
      condition     = var.vm_backup_policy != null
      error_message = "protected_vm_ids requires vm_backup_policy: the VMs are enrolled in the module's VM backup policy."
    }
  }
}
