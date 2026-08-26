<!-- BEGIN_TF_DOCS -->
# Site Recovery VM Replication Example

This example demonstrates cross-region Azure Site Recovery replication for Windows virtual machines using a pair of Recovery Services Vault deployments and the Site Recovery resources required to connect them.

## What this example shows

- Creating source and target resource groups, networks, and vaults for a full ASR topology
- Configuring Site Recovery fabrics, protection containers, container mapping, and network mapping
- Creating source VMs and enabling replication to a secondary region
- A working replicated VM configuration that defaults the target VM size to a source-compatible SKU to avoid ASR disk-controller compatibility failures

## Notes Before You Run It

- This is the heaviest example in the repository and can take a long time to apply
- The example currently focuses on reliable OS-disk replication for the protected VMs
- You need permissions to create Recovery Services, networking, storage, compute, and role assignment resources in both regions

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.12)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.1)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.12)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.1)

## Resources

The following resources are used by this module:

- [azapi_resource.managed_disk_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.network_interface_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.resource_group_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.resource_group_target](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_fabric_primary](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_fabric_secondary](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_network_mapping](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_protection_container_mapping](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_protection_container_primary](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_protection_container_secondary](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_replicated_vm](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.site_recovery_replication_policy](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.storage_account_contributor_assignment](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.storage_account_staging](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.storage_blob_data_contributor_assignment](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.storage_queue_data_contributor_assignment](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.subnet_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.subnet_target](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.virtual_machine_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.virtual_network_source](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.virtual_network_target](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_update_resource.site_recovery_replicated_vm_configuration](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) (resource)
- [random_integer.region_seed](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_password.vm_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_string.storage_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.storage_account_contributor_assignment](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [random_uuid.storage_blob_data_contributor_assignment](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [random_uuid.storage_queue_data_contributor_assignment](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_site_recovery_replication_timeouts"></a> [site\_recovery\_replication\_timeouts](#input\_site\_recovery\_replication\_timeouts)

Description: Timeouts for replicated VM Site Recovery operations. Increase these when Azure replication operations are slow to report completion.

Type:

```hcl
object({
    create = string
    update = string
    delete = string
    read   = string
  })
```

Default:

```json
{
  "create": "180m",
  "delete": "120m",
  "read": "15m",
  "update": "180m"
}
```

### <a name="input_source_vm_size"></a> [source\_vm\_size](#input\_source\_vm\_size)

Description: VM SKU for source VMs used in the Site Recovery example.

Type: `string`

Default: `"Standard_D2as_v5"`

### <a name="input_source_vms"></a> [source\_vms](#input\_source\_vms)

Description: Map of source VMs and their data disks for Site Recovery replication.

Type:

```hcl
map(object({
    data_disks = map(object({
      lun     = number
      size_gb = number
    }))
  }))
```

Default:

```json
{
  "vm1": {
    "data_disks": {
      "data1": {
        "lun": 0,
        "size_gb": 32
      },
      "data2": {
        "lun": 1,
        "size_gb": 64
      }
    }
  },
  "vm2": {
    "data_disks": {
      "data1": {
        "lun": 0,
        "size_gb": 32
      },
      "data2": {
        "lun": 1,
        "size_gb": 128
      }
    }
  }
}
```

### <a name="input_target_vm_size"></a> [target\_vm\_size](#input\_target\_vm\_size)

Description: VM SKU used for failover target replicated VMs. Must be compatible with the source VM's disk controller type (SCSI) and generation; incompatible sizes cause Azure Site Recovery error 1400148. Defaults to the source VM size to guarantee compatibility.

Type: `string`

Default: `"Standard_D2as_v5"`

## Outputs

The following outputs are exported:

### <a name="output_rsv_primary"></a> [rsv\_primary](#output\_rsv\_primary)

Description: n/a

### <a name="output_rsv_secondary"></a> [rsv\_secondary](#output\_rsv\_secondary)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_recovery_services_vault_primary"></a> [recovery\_services\_vault\_primary](#module\_recovery\_services\_vault\_primary)

Source: ../../

Version:

### <a name="module_recovery_services_vault_secondary"></a> [recovery\_services\_vault\_secondary](#module\_recovery\_services\_vault\_secondary)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->