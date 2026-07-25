# terraform-azurerm-backup

Terraform module that manages [Azure Backup](https://azure.microsoft.com/products/backup).
It creates a recovery services vault and, optionally, a VM backup policy with a
daily or weekly schedule and matching retention, exposing the vault and policy IDs.

## Usage

```hcl
module "backup" {
  source = "github.com/moveeeax/terraform-azurerm-backup"

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

Runnable examples live in [`examples/basic`](examples/basic) and
[`examples/weekly`](examples/weekly).

## Data protection defaults

| Setting                        | Default          | Why |
|--------------------------------|------------------|-----|
| `soft_delete_enabled`          | `true`           | Retains deleted backup items for 14 days. Turning it off removes the only guard against a deletion of the backups themselves. |
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
| azurerm   | >= 3.0, < 5.0   |

The azurerm floor is verified against 3.0.0. The upper bound is deliberate:
azurerm 4.x already reports `soft_delete_enabled` as deprecated and slated for
removal in 5.0.

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
| `soft_delete_enabled`          | Whether soft delete is enabled for the vault.                    | `bool`        | `true`           |    no    |
| `storage_mode_type`            | Storage redundancy: `GeoRedundant`, `LocallyRedundant` or `ZoneRedundant`. | `string` | `"GeoRedundant"` |  no  |
| `cross_region_restore_enabled` | Whether cross region restore is enabled. Requires `GeoRedundant`.| `bool`        | `false`          |    no    |
| `vm_backup_policy`             | Optional VM backup policy to create in the vault.                | `object`      | `null`           |    no    |
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

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test
```

## License

[MIT](LICENSE)
