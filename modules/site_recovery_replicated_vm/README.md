<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.12 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 2.12 |

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
| <a name="input_ignore_body_changes"></a> [ignore\_body\_changes](#input\_ignore\_body\_changes) | Body-relative paths to ignore for the AzAPI resource owned by this module. Paths use dot notation, e.g. `properties.policyId`.<br/>Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.<br/><br/>- `recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items` - Paths ignored on the replication protected item resource. | <pre>object({<br/>    recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_resource_types"></a> [resource\_types](#input\_resource\_types) | AzAPI resource types and API versions used by this module.<br/><br/>- `recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items` - Resource type and API version for the Azure Site Recovery replication protected item and its post-enablement update action. | <pre>object({<br/>    recoveryservices_vaults_replication_fabrics_replication_protection_containers_replication_protected_items = optional(string, "Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems@2024-10-01")<br/>  })</pre> | `{}` | no |
| <a name="input_retry"></a> [retry](#input\_retry) | Retry configuration applied to the AzAPI resources created by this module.<br/><br/>- `error_message_regex` - A list of regular expressions matched against the error message returned by Azure. A matching error is retried.<br/>- `interval_seconds` - The initial number of seconds to wait before the first retry.<br/>- `max_interval_seconds` - The maximum number of seconds to wait between retries.<br/>- `multiplier` - The factor by which the retry interval grows after each attempt.<br/>- `randomization_factor` - The random jitter applied to each retry interval. Set to `0` to disable jitter. | <pre>object({<br/>    error_message_regex  = optional(list(string), ["ReferencedResourceNotProvisioned"])<br/>    interval_seconds     = optional(number, 10)<br/>    max_interval_seconds = optional(number, 180)<br/>    multiplier           = optional(number, 1.5)<br/>    randomization_factor = optional(number, 0.5)<br/>  })</pre> | `{}` | no |
| <a name="input_site_recovery_replicated_vm"></a> [site\_recovery\_replicated\_vm](#input\_site\_recovery\_replicated\_vm) | Configuration for site recovery replicated VM. Either target\_resource\_group\_id or recovery\_resource\_group\_id must be set. | <pre>object({<br/>    source_vm_id                     = string<br/>    recovery_vault_name              = string<br/>    vault_resource_group_name        = string<br/>    source_recovery_fabric_name      = string<br/>    source_protection_container_name = string<br/>    recovery_replication_policy_id   = string<br/>    target_resource_id               = string<br/>    target_resource_group_id         = optional(string, null)<br/>    target_recovery_fabric_id        = optional(string, null)<br/>    target_protection_container_id   = optional(string, null)<br/>    target_virtual_machine_size      = optional(string, null)<br/>    managed_disk = optional(map(object({<br/>      disk_id                       = string<br/>      staging_storage_account_id    = string<br/>      target_resource_group_id      = optional(string, null)<br/>      target_disk_type              = optional(string, "Standard_LRS")<br/>      target_replica_disk_type      = optional(string, "Standard_LRS")<br/>      target_disk_encryption_set_id = optional(string, null)<br/>    })), null)<br/>    unmanaged_disk = optional(map(object({<br/>      disk_uri                   = string<br/>      staging_storage_account_id = optional(string, null)<br/>      target_storage_account_id  = optional(string, null)<br/>    })), null)<br/>    target_network_id                      = optional(string, null)<br/>    target_subnet_name                     = optional(string, null)<br/>    target_static_ip                       = optional(string, null)<br/>    test_network_id                        = optional(string, null)<br/>    test_subnet_name                       = optional(string, null)<br/>    recovery_resource_group_id             = optional(string, null)<br/>    recovery_storage_account_id            = optional(string, null)<br/>    recovery_target_disk_encryption_set_id = optional(string, null)<br/>    multi_vm_group_name                    = optional(string, null)<br/>    timeouts = optional(object({<br/>      create = optional(string, "60m")<br/>      delete = optional(string, "60m")<br/>      read   = optional(string, "5m")<br/>      update = optional(string, "60m")<br/>    }), {})<br/>  })</pre> | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Operation timeouts applied to the AzAPI resources created by this module. Values use Go duration strings, e.g. `60m`.<br/>Any value set through `site_recovery_replicated_vm.timeouts` takes precedence over the matching value here.<br/><br/>- `create` - The timeout for create operations.<br/>- `delete` - The timeout for delete operations.<br/>- `read` - The timeout for read operations.<br/>- `update` - The timeout for update operations. | <pre>object({<br/>    create = optional(string)<br/>    delete = optional(string)<br/>    read   = optional(string)<br/>    update = optional(string)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_body"></a> [body](#output\_body) | The configured AzAPI request body sent to Azure for the Azure Site Recovery replication protected item. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Azure Site Recovery replication protected item. |
| <a name="output_parent_id"></a> [parent\_id](#output\_parent\_id) | The ARM resource ID of the source replication protection container that contains the replication protected item. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The ARM resource ID of the Azure Site Recovery replication protected item. |
<!-- END_TF_DOCS -->