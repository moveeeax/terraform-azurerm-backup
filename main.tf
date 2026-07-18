resource "azurerm_recovery_services_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  soft_delete_enabled = var.soft_delete_enabled

  tags = var.tags
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
  }

  retention_daily {
    count = var.vm_backup_policy.retention_daily_count
  }
}
