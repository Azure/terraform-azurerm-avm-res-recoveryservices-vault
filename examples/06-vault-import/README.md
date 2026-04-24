<!-- BEGIN_TF_DOCS -->
# Vault Import Example

This example demonstrates how to import a pre-existing Recovery Services Vault
into Terraform management using this module.

## Overview

A common operational scenario is bringing an existing Azure Recovery Services
Vault (created manually, via the Portal, or by a different Terraform
configuration) under management of this AVM module.

The example is structured in two conceptual phases:

**Phase 1 – Pre-existing vault**
An `azapi_resource` block represents a vault that already exists in Azure before
the module is introduced. In real usage this block would not be present; the
vault simply exists.

**Phase 2 – Import and manage with the module**
An `import {}` block brings the pre-existing vault under the module's management.
The `module "recovery_services_vault_imported"` block is the authoritative,
ongoing configuration for the vault going forward.

### Workflow

```
┌────────────────────────────────────────────────────────────┐
│ terraform apply  (first run)                               │
│                                                            │
│  1. azapi_resource.vault_existing  → creates the vault     │
│  2. import { … }                   → imports vault into    │
│                                      module address        │
│  3. module.recovery_services_vault_imported                │
│                            → manages the imported vault    │
└────────────────────────────────────────────────────────────┘

After the first successful apply, remove the pre-existing resource
from state so only the module address manages the vault:

  terraform state rm 'azapi_resource.vault_existing'

Then remove (or comment out) the azapi_resource.vault_existing block
from main.tf. Subsequent terraform plan/apply calls will only use
the module.
```

## Data Collection

The software may collect information about you and your use of the software and
send it to Microsoft. Microsoft may use this information to provide services and
improve our products and services. You may turn off the telemetry as described
in the [repository](https://aka.ms/avm/telemetry). There are also some features
in the software that may enable you and Microsoft to collect data from users of
your applications. If you use these features, you must comply with applicable
law, including providing appropriate notices to users of your applications
together with a copy of Microsoft's privacy statement. Our privacy statement is
located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more
about data collection and use in the help documentation and our privacy
statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.34.0, < 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 2.4 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.34.0, < 5.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.vault_existing](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) | data source |

<!-- markdownlint-disable MD013 -->
## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The resource ID of the imported Recovery Services Vault. |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_region"></a> [azure\_region](#module\_azure\_region) | claranet/regions/azurerm | 7.1.1 |
| <a name="module_naming"></a> [naming](#module\_naming) | Azure/naming/azurerm | 0.4.0 |
| <a name="module_recovery_services_vault_imported"></a> [recovery\_services\_vault\_imported](#module\_recovery\_services\_vault\_imported) | ../../ | n/a |

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
