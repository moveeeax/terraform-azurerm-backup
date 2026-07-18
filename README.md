# terraform-azurerm-backup

Terraform module that manages [Azure Backup](https://azure.microsoft.com/products/backup).
It creates a recovery services vault and, optionally, a VM backup policy with a
daily schedule and retention, exposing the vault and policy IDs.

## Usage

```hcl
module "backup" {
  source = "github.com/cybercapybara/terraform-azurerm-backup"

  name                = "prod-vault"
  resource_group_name = "prod-rg"
  location            = "eastus"

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

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                  | Description                                                      | Type          | Default      | Required |
|-----------------------|------------------------------------------------------------------|---------------|--------------|:--------:|
| `name`                | Name of the recovery services vault.                             | `string`      | n/a          |   yes    |
| `resource_group_name` | Name of the resource group in which to create the vault.         | `string`      | n/a          |   yes    |
| `location`            | Azure region in which to create the vault.                       | `string`      | n/a          |   yes    |
| `sku`                 | SKU of the vault: Standard or RS0.                               | `string`      | `"Standard"` |    no    |
| `soft_delete_enabled` | Whether soft delete is enabled for the vault.                    | `bool`        | `true`       |    no    |
| `vm_backup_policy`    | Optional VM backup policy to create in the vault.                | `object`      | `null`       |    no    |
| `tags`                | Map of tags applied to the vault.                                | `map(string)` | `{}`         |    no    |

## Outputs

| Name                  | Description                                    |
|-----------------------|------------------------------------------------|
| `vault_id`            | ID of the recovery services vault.             |
| `vault_name`          | Name of the recovery services vault.           |
| `vm_backup_policy_id` | ID of the VM backup policy, if one was created.|

## License

[MIT](LICENSE)
