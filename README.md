# terraform-azurerm-backup

Terraform module that manages [Azure Backup](https://azure.microsoft.com/products/backup).
It creates a recovery services vault and, optionally, a VM backup policy with a
daily or weekly schedule and matching retention, enrols VMs in that policy, and
exposes the vault, policy and protected item IDs.

## Usage

```hcl
module "backup" {
  source = "github.com/moveeeax/terraform-azurerm-backup?ref=v1.0.0"

  name                = "prod-vault"
  resource_group_name = "prod-rg"
  location            = "eastus"

  # Geo-redundant storage keeps backup data available if the primary region is
  # lost, and is a prerequisite for cross region restore.
  storage_mode_type            = "GeoRedundant"
  cross_region_restore_enabled = true

  vm_backup_policy = {
    name                  = "prod-daily"
    backup_time           = "02:00"
    retention_daily_count = 30
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A weekly schedule names the days it runs on; the module emits both the schedule
weekdays and the matching weekly retention block:

```hcl
vm_backup_policy = {
  name                   = "prod-weekly"
  backup_frequency       = "Weekly"
  backup_time            = "02:30"
  backup_weekdays        = ["Sunday", "Wednesday"]
  retention_weekly_count = 12
}
```

## Protecting VMs

`protected_vm_ids` enrols VMs in the module's policy, one
`azurerm_backup_protected_vm` per entry. It requires `vm_backup_policy`; a map
without a policy fails at plan time. The default is `{}`, so upgrading the
module enrols nothing on its own: list every VM that should be backed up.

```hcl
vm_backup_policy = {
  name                  = "prod-daily"
  retention_daily_count = 30
}

protected_vm_ids = {
  web = azurerm_linux_virtual_machine.web.id
  db  = azurerm_linux_virtual_machine.db.id
}
```

The keys are labels that end up in resource addresses
(`azurerm_backup_protected_vm.this["web"]`), so they must be known at plan time
and should stay stable: renaming a key destroys the protected item (which stops
protection for that VM) and creates it again, unless a `moved` block maps the old
key to the new one. The values may be IDs of VMs created in the same apply.
`protected_item_ids` returns the protected item IDs under the same keys.

A VM already protected outside this module (for example through
`azurerm_backup_protected_vm` in the caller) has to be removed from that
configuration and imported to `module.backup.azurerm_backup_protected_vm.this["<key>"]`
first. Otherwise two configurations manage the same protected item and each
apply undoes the other's changes.

Runnable examples live in [`examples/basic`](examples/basic) and
[`examples/weekly`](examples/weekly).

## Data protection defaults

| Setting                        | Default          | Why |
|--------------------------------|------------------|-----|
| Soft delete                    | enabled (Azure default) | Retains deleted backup items for 14 days. The module no longer manages it (azurerm 5.0 removed the argument); `soft_delete_enabled = false` is rejected at plan time. |
| `storage_mode_type`            | `"GeoRedundant"` | Backup data is replicated to the paired region, so a regional failure does not take the backups with it. |
| `cross_region_restore_enabled` | `false`          | Matches the Azure default. Enable it to restore into the paired region; it requires `storage_mode_type = "GeoRedundant"` and adds cost. |

Azure's own limits on the policy inputs are validated at plan time rather than
at apply time: `retention_daily_count` must be 7-9999, `retention_weekly_count`
must be 1-5163, `instant_restore_retention_days` must be 1-5, and `backup_time`
must land on a half hour.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.5          |
| azurerm   | >= 3.0, < 6.0   |

CI validates the module against the 3.0.0 floor and tests it against the latest
5.x release. azurerm 5.0 removed `soft_delete_enabled` from
`azurerm_recovery_services_vault`, so the module no longer sets it and soft
delete stays at the Azure default (enabled). The `soft_delete_enabled` input is
kept for compatibility but only accepts `true`; 6.x is excluded until tested.

Running the test suite (`terraform test`) additionally needs Terraform >= 1.7
for `mock_provider`. That is a test-only requirement and does not apply to
consumers of the module.

## Inputs

| Name                           | Description                                                      | Type          | Default          | Required |
|--------------------------------|------------------------------------------------------------------|---------------|------------------|:--------:|
| `name`                         | Name of the recovery services vault.                             | `string`      | n/a              |   yes    |
| `resource_group_name`          | Name of the resource group in which to create the vault.         | `string`      | n/a              |   yes    |
| `location`                     | Azure region in which to create the vault.                       | `string`      | n/a              |   yes    |
| `sku`                          | SKU of the vault: `Standard` or `RS0`.                           | `string`      | `"Standard"`     |    no    |
| `soft_delete_enabled`          | Deprecated. Only `true` is accepted; soft delete stays enabled.  | `bool`        | `true`           |    no    |
| `storage_mode_type`            | Storage redundancy: `GeoRedundant`, `LocallyRedundant` or `ZoneRedundant`. | `string` | `"GeoRedundant"` |  no  |
| `cross_region_restore_enabled` | Whether cross region restore is enabled. Requires `GeoRedundant`.| `bool`        | `false`          |    no    |
| `vm_backup_policy`             | Optional VM backup policy to create in the vault.                | `object`      | `null`           |    no    |
| `protected_vm_ids`             | VMs to enrol in the VM backup policy, as key => VM ID. Requires `vm_backup_policy`. | `map(string)` | `{}` | no |
| `tags`                         | Map of tags applied to the vault.                                | `map(string)` | `{}`             |    no    |

### `vm_backup_policy` object

| Field                            | Type           | Default    | Notes |
|----------------------------------|----------------|------------|-------|
| `name`                           | `string`       | n/a        | Required. |
| `timezone`                       | `string`       | `"UTC"`    | Timezone the schedule is evaluated in. |
| `backup_frequency`               | `string`       | `"Daily"`  | `Daily` or `Weekly`. |
| `backup_time`                    | `string`       | `"23:00"`  | `HH:MM`; Azure only accepts `:00` or `:30`. |
| `backup_weekdays`                | `list(string)` | `[]`       | Full English day names. Required when `backup_frequency` is `Weekly`. |
| `retention_daily_count`          | `number`       | `7`        | Used when `backup_frequency` is `Daily`. Azure requires 7-9999. |
| `retention_weekly_count`         | `number`       | `4`        | Used when `backup_frequency` is `Weekly`. Azure requires 1-5163. |
| `instant_restore_retention_days` | `number`       | `2`        | Azure requires 1-5 for this policy type. |

## Outputs

| Name                  | Description                                    |
|-----------------------|------------------------------------------------|
| `vault_id`            | ID of the recovery services vault.             |
| `vault_name`          | Name of the recovery services vault.           |
| `vm_backup_policy_id` | ID of the VM backup policy, if one was created.|
| `protected_item_ids`  | Map of protected item IDs, keyed like `protected_vm_ids`. |

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test
```

## License

[MIT](LICENSE)
