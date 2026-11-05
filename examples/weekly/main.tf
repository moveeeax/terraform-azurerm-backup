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

# A weekly schedule must name the days it runs on and pair with weekly
# retention; the module emits both from backup_weekdays.
module "backup" {
  source = "../.."

  name                = "example-weekly-vault"
  resource_group_name = "example-rg"
  location            = "eastus"

  vm_backup_policy = {
    name                   = "example-weekly"
    backup_frequency       = "Weekly"
    backup_time            = "02:30"
    backup_weekdays        = ["Sunday", "Wednesday"]
    retention_weekly_count = 12
  }

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "vm_backup_policy_id" {
  value = module.backup.vm_backup_policy_id
}
