<!-- BEGIN_TF_DOCS -->
# Site Recovery Replicated VM Module

This module creates and manages Azure Site Recovery replicated virtual machines within a Recovery Services Vault.

## Resources

The following resources are created:
- `azurerm_site_recovery_replicated_vm` - The replicated VM resource for disaster recovery

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.50, < 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| site_recovery_replicated_vm | Configuration for site recovery replicated VM | <pre>object({<br>    source_vm_id                     = string<br>    recovery_vault_name              = string<br>    vault_resource_group_name        = string<br>    source_recovery_fabric_name      = string<br>    source_protection_container_name = string<br>    recovery_replication_policy_id   = string<br>    target_resource_id               = string<br>    target_recovery_fabric_id        = optional(string, null)<br>    target_protection_container_id   = optional(string, null)<br>    managed_disk = optional(map(object({<br>      disk_id                    = string<br>      staging_storage_account_id = string<br>    })), null)<br>    unmanaged_disk = optional(map(object({<br>      disk_uri             = string<br>      staging_storage_name = string<br>    })), null)<br>    target_network_id           = optional(string, null)<br>    target_subnet_name          = optional(string, null)<br>    target_static_ip            = optional(string, null)<br>    test_network_id             = optional(string, null)<br>    test_subnet_name            = optional(string, null)<br>    recovery_resource_group_id  = optional(string, null)<br>    recovery_storage_account_id = optional(string, null)<br>    recovery_target_disk_encryption_set_id = optional(string, null)<br>    multi_vm_group_name         = optional(string, null)<br>    multi_vm_group_create_option = optional(string, "SingleVm")<br>    tags                        = optional(map(string), {})<br>    timeouts = optional(object({<br>      create = optional(string, "60m")<br>      delete = optional(string, "60m")<br>      read   = optional(string, "5m")<br>      update = optional(string, "60m")<br>    }), {})<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| resource | The site recovery replicated VM resource |
| resource_id | The resource ID of the site recovery replicated VM |

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve Microsoft products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from end users of your applications that incorporate Microsoft code from the software.

If you are collecting end user data with the software, you must comply with applicable laws, including providing appropriate notices to end users and you should provide a copy of Microsoft's privacy statement to end users (https://privacy.microsoft.com/privacystatement). Microsoft's privacy statement describes the personal data Microsoft processes and the commitments we make about that data.
<!-- END_TF_DOCS -->
