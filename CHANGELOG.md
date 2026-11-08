# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-08

### Added

- `protected_vm_ids` (`map(string)`, key => VM ID) enrols VMs in the module's
  VM backup policy through `azurerm_backup_protected_vm`, and the
  `protected_item_ids` output returns their IDs under the same keys. Requires
  `vm_backup_policy`. Defaults to `{}`, so existing deployments plan no change.

## [1.1.0] - 2026-11-05

### Changed

- Breaking: the module no longer sets `soft_delete_enabled` on the vault, so it
  works with azurerm 5.x, which removed the argument. `soft_delete_enabled` is
  kept for compatibility but only accepts `true`.

## [1.0.0] - 2026-07-26

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-backup/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-azurerm-backup/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-backup/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-backup/releases/tag/v1.0.0
