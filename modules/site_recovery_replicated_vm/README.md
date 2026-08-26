<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource_action.target_settings](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action) | resource |
| [azapi_client_config.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_site_recovery_replicated_vm"></a> [site\_recovery\_replicated\_vm](#input\_site\_recovery\_replicated\_vm) | Configuration for site recovery replicated VM. Either target\_resource\_group\_id or recovery\_resource\_group\_id must be set. | <pre>object({<br/>    source_vm_id                     = string<br/>    recovery_vault_name              = string<br/>    vault_resource_group_name        = string<br/>    source_recovery_fabric_name      = string<br/>    source_protection_container_name = string<br/>    recovery_replication_policy_id   = string<br/>    target_resource_id               = string<br/>    target_resource_group_id         = optional(string, null)<br/>    target_recovery_fabric_id        = optional(string, null)<br/>    target_protection_container_id   = optional(string, null)<br/>    target_virtual_machine_size      = optional(string, null)<br/>    managed_disk = optional(map(object({<br/>      disk_id                       = string<br/>      staging_storage_account_id    = string<br/>      target_resource_group_id      = optional(string, null)<br/>      target_disk_type              = optional(string, "Standard_LRS")<br/>      target_replica_disk_type      = optional(string, "Standard_LRS")<br/>      target_disk_encryption_set_id = optional(string, null)<br/>    })), null)<br/>    unmanaged_disk = optional(map(object({<br/>      disk_uri                   = string<br/>      staging_storage_account_id = optional(string, null)<br/>      target_storage_account_id  = optional(string, null)<br/>    })), null)<br/>    target_network_id                      = optional(string, null)<br/>    target_subnet_name                     = optional(string, null)<br/>    target_static_ip                       = optional(string, null)<br/>    test_network_id                        = optional(string, null)<br/>    test_subnet_name                       = optional(string, null)<br/>    recovery_resource_group_id             = optional(string, null)<br/>    recovery_storage_account_id            = optional(string, null)<br/>    recovery_target_disk_encryption_set_id = optional(string, null)<br/>    multi_vm_group_name                    = optional(string, null)<br/>    timeouts = optional(object({<br/>      create = optional(string, "60m")<br/>      delete = optional(string, "60m")<br/>      read   = optional(string, "5m")<br/>      update = optional(string, "60m")<br/>    }), {})<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource"></a> [resource](#output\_resource) | The `azapi_resource` object for the Azure Site Recovery replication protected item (`Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems`). This is an AzAPI resource object, not the legacy AzureRM `azurerm_site_recovery_replicated_vm` object. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The ARM resource ID of the Azure Site Recovery replication protected item. |
<!-- END_TF_DOCS -->