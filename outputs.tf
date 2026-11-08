output "vault_id" {
  description = "ID of the recovery services vault."
  value       = azurerm_recovery_services_vault.this.id
}

output "vault_name" {
  description = "Name of the recovery services vault."
  value       = azurerm_recovery_services_vault.this.name
}

output "vm_backup_policy_id" {
  description = "ID of the VM backup policy, if one was created."
  value       = try(azurerm_backup_policy_vm.this[0].id, null)
}

output "protected_item_ids" {
  description = "Map of protected item IDs, keyed like protected_vm_ids."
  value       = { for key, item in azurerm_backup_protected_vm.this : key => item.id }
}
