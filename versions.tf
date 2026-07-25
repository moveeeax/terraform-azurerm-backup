terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Floor verified against azurerm 3.0.0: soft_delete_enabled,
      # storage_mode_type and cross_region_restore_enabled are all present.
      # Upper bound because azurerm 4.x already reports soft_delete_enabled as
      # deprecated and slated for removal in 5.0, which would break this module.
      version = ">= 3.0, < 5.0"
    }
  }
}
