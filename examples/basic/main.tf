terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
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

  vm_backup_policy = {
    name                  = "example-daily"
    backup_time           = "23:00"
    retention_daily_count = 14
  }

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "vault_id" {
  value = module.backup.vault_id
}
