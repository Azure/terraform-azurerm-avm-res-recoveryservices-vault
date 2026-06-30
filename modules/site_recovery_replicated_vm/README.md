Error: unable to decode config, 1 error(s) decoding:

* 'recursive' expected a map, got 'bool'

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.50, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.50, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_site_recovery_replicated_vm.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/site_recovery_replicated_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_site_recovery_replicated_vm"></a> [site\_recovery\_replicated\_vm](#input\_site\_recovery\_replicated\_vm) | Configuration for site recovery replicated VM | <pre>object({<br>    source_vm_id                     = string<br>    recovery_vault_name              = string<br>    vault_resource_group_name        = string<br>    source_recovery_fabric_name      = string<br>    source_protection_container_name = string<br>    recovery_replication_policy_id   = string<br>    target_resource_id               = string<br>    target_recovery_fabric_id        = optional(string, null)<br>    target_protection_container_id   = optional(string, null)<br>    managed_disk = optional(map(object({<br>      disk_id                    = string<br>      staging_storage_account_id = string<br>    })), null)<br>    unmanaged_disk = optional(map(object({<br>      disk_uri = string<br>    })), null)<br>    target_network_id           = optional(string, null)<br>    target_subnet_name          = optional(string, null)<br>    target_static_ip            = optional(string, null)<br>    test_network_id             = optional(string, null)<br>    test_subnet_name            = optional(string, null)<br>    recovery_resource_group_id  = optional(string, null)<br>    recovery_storage_account_id = optional(string, null)<br>    recovery_target_disk_encryption_set_id = optional(string, null)<br>    multi_vm_group_name         = optional(string, null)<br>    timeouts = optional(object({<br>      create = optional(string, "60m")<br>      delete = optional(string, "60m")<br>      read   = optional(string, "5m")<br>      update = optional(string, "60m")<br>    }), {})<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource"></a> [resource](#output\_resource) | The site recovery replicated VM resource |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The resource ID of the site recovery replicated VM |
<!-- END_TF_DOCS -->