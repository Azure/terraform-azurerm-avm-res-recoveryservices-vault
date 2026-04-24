<!-- BEGIN_TF_DOCS -->
# Import Existing Vault example

This example demonstrates how to import a pre-existing Azure Recovery Services Vault
into Terraform management using the `import` block.

## Why this example exists

The Terraform `import` block requires its `id` argument to be a value known at
**plan time**. Referencing another resource's attribute (e.g.
`azapi_resource.vault_existing.id`) causes this error:

```
Error: Invalid import id argument
The import block "id" argument depends on resource attributes that cannot
be determined until apply, so Terraform cannot plan to import this resource.
```

The fix is to **construct the Azure Resource ID directly from variables**:

```hcl
locals {
  vault_resource_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.vault_name}"
}

import {
  id = local.vault_resource_id   # known at plan time ✓
  to = module.recovery_services_vault.azapi_resource.this
}
```

## Two-step apply workflow

Because the vault must exist in Azure **before** `terraform apply` can import it,
this example includes a `null_resource` that creates the vault via Azure CLI.
Run the two steps below if starting from scratch:

```bash
# Step 1 – provision the resource group and create the vault via CLI
terraform apply -target=azurerm_resource_group.this \
                -target=null_resource.ensure_vault_exists

# Step 2 – import the vault and bring the full configuration under management
terraform apply
```

If the vault already exists in Azure, skip Step 1 and run Step 2 directly.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.34.0, < 5.0.0)

- <a name="requirement_null"></a> [null](#requirement\_null) (>= 3.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.4)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 4.34.0, < 5.0.0)

- <a name="provider_null"></a> [null](#provider\_null) (>= 3.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [null_resource.ensure_vault_exists](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: Controls whether telemetry is sent to Microsoft. Defaults to true.

Type: `bool`

Default: `true`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the vault is (or will be) located.

Type: `string`

Default: `"eastus"`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: Name of the resource group that contains (or will contain) the vault.

Type: `string`

Default: `"rg-import-vault-006"`

### <a name="input_sku"></a> [sku](#input\_sku)

Description: SKU of the Recovery Services Vault. Allowed values: RS0, Standard.

Type: `string`

Default: `"RS0"`

### <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name)

Description: Name of the Recovery Services Vault to import.

Type: `string`

Default: `"rsv-import-example-006"`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The Recovery Services Vault resource.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The resource ID of the Recovery Services Vault.

## Modules

The following Modules are called:

### <a name="module_recovery_services_vault"></a> [recovery\_services\_vault](#module\_recovery\_services\_vault)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->