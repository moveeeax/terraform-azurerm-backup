terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 6.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "backup" {
  source = "../.."

  name                = "example-vault"
  resource_group_name = "example-rg"
  location            = "eastus"

  # Geo-redundant storage keeps backup data available if the primary region is
  # lost, and is a prerequisite for cross region restore.
  storage_mode_type            = "GeoRedundant"
  cross_region_restore_enabled = true

  vm_backup_policy = {
    name                  = "example-daily"
    backup_time           = "23:00"
    retention_daily_count = 14
  }

  # Each VM is enrolled in the policy above. The keys are labels used in
  # resource addresses; the values can come from VMs created alongside.
  protected_vm_ids = {
    web = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Compute/virtualMachines/example-web"
  }

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "vault_id" {
  value = module.backup.vault_id
}

output "protected_item_ids" {
  value = module.backup.protected_item_ids
}
