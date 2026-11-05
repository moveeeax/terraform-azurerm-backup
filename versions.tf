terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Floor verified against azurerm 3.0.0: storage_mode_type and
      # cross_region_restore_enabled are present. soft_delete_enabled is no
      # longer set (removed in 5.0), so 3.x, 4.x and 5.x all work.
      # Ceiling: tested against 5.x; 6.0 has not been vetted.
      version = ">= 3.0, < 6.0"
    }
  }
}
