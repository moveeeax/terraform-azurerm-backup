# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports terraform >= 1.5 -- do not raise required_version
# in versions.tf on account of these tests.
mock_provider "azurerm" {}

variables {
  name                = "test-vault"
  resource_group_name = "test-rg"
  location            = "eastus"
}

run "rejects_disabling_soft_delete" {
  command = plan

  variables {
    soft_delete_enabled = false
  }

  expect_failures = [var.soft_delete_enabled]
}

run "vault_defaults_protect_backup_data" {
  assert {
    condition     = azurerm_recovery_services_vault.this.storage_mode_type == "GeoRedundant"
    error_message = "Vault storage must default to GeoRedundant so backup data survives a regional failure."
  }

  assert {
    condition     = length(azurerm_backup_policy_vm.this) == 0
    error_message = "No backup policy should be created when vm_backup_policy is null."
  }
}

run "daily_policy_emits_daily_retention_only" {
  variables {
    vm_backup_policy = {
      name                  = "test-daily"
      backup_time           = "02:00"
      retention_daily_count = 30
    }
  }

  assert {
    condition     = length(azurerm_backup_policy_vm.this[0].retention_daily) == 1
    error_message = "A Daily policy must carry a retention_daily block."
  }

  assert {
    condition     = azurerm_backup_policy_vm.this[0].retention_daily[0].count == 30
    error_message = "retention_daily count must match retention_daily_count."
  }

  assert {
    condition     = length(azurerm_backup_policy_vm.this[0].retention_weekly) == 0
    error_message = "A Daily policy must not carry a retention_weekly block."
  }

  assert {
    condition = azurerm_backup_policy_vm.this[0].backup[0].weekdays == null ? true : (
      length(azurerm_backup_policy_vm.this[0].backup[0].weekdays) == 0
    )
    error_message = "A Daily schedule must not name weekdays."
  }
}

run "weekly_policy_emits_weekly_retention_and_weekdays" {
  variables {
    vm_backup_policy = {
      name                   = "test-weekly"
      backup_frequency       = "Weekly"
      backup_weekdays        = ["Sunday"]
      retention_weekly_count = 6
    }
  }

  assert {
    condition     = length(azurerm_backup_policy_vm.this[0].retention_weekly) == 1
    error_message = "A Weekly policy must carry a retention_weekly block; without it Azure rejects the policy."
  }

  assert {
    condition     = azurerm_backup_policy_vm.this[0].retention_weekly[0].count == 6
    error_message = "retention_weekly count must match retention_weekly_count."
  }

  assert {
    condition     = length(azurerm_backup_policy_vm.this[0].retention_daily) == 0
    error_message = "A Weekly policy must not carry a retention_daily block."
  }

  assert {
    condition     = contains(azurerm_backup_policy_vm.this[0].backup[0].weekdays, "Sunday")
    error_message = "A Weekly schedule must name the weekdays it runs on."
  }
}

run "rejects_weekly_policy_without_weekdays" {
  command = plan

  variables {
    vm_backup_policy = {
      name             = "test-weekly"
      backup_frequency = "Weekly"
    }
  }

  expect_failures = [var.vm_backup_policy]
}

run "rejects_unknown_backup_frequency" {
  command = plan

  variables {
    vm_backup_policy = {
      name             = "test-monthly"
      backup_frequency = "Monthly"
    }
  }

  expect_failures = [var.vm_backup_policy]
}

run "rejects_retention_that_protects_nothing" {
  command = plan

  variables {
    vm_backup_policy = {
      name                  = "test-daily"
      retention_daily_count = 0
    }
  }

  expect_failures = [var.vm_backup_policy]
}

run "rejects_retention_below_azure_daily_minimum" {
  command = plan

  variables {
    vm_backup_policy = {
      name                  = "test-daily"
      retention_daily_count = 6
    }
  }

  expect_failures = [var.vm_backup_policy]
}

run "rejects_backup_time_off_the_half_hour" {
  command = plan

  variables {
    vm_backup_policy = {
      name        = "test-daily"
      backup_time = "02:15"
    }
  }

  expect_failures = [var.vm_backup_policy]
}

run "rejects_out_of_range_instant_restore_retention" {
  command = plan

  variables {
    vm_backup_policy = {
      name                           = "test-daily"
      instant_restore_retention_days = 9
    }
  }

  expect_failures = [var.vm_backup_policy]
}

run "rejects_invalid_sku" {
  command = plan

  variables {
    sku = "NotASku"
  }

  expect_failures = [var.sku]
}

run "rejects_invalid_storage_mode_type" {
  command = plan

  variables {
    storage_mode_type = "SuperRedundant"
  }

  expect_failures = [var.storage_mode_type]
}

run "rejects_cross_region_restore_without_geo_redundant_storage" {
  command = plan

  variables {
    storage_mode_type            = "LocallyRedundant"
    cross_region_restore_enabled = true
  }

  expect_failures = [azurerm_recovery_services_vault.this]
}
