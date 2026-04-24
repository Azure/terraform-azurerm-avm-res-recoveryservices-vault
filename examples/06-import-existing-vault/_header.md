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
