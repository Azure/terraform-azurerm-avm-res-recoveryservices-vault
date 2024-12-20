# terraform-azurerm-avm-recoveryservices-vault

This terraform module is designed to deploy Azure Recovery Services Vault. It has support to create private link private endpoints to make the resource privately accessible via customer's private virtual networks and use a customer managed encryption key.

## Features

* Create an Azure recovery services vault resource with options such as immutability, soft delete, storage type, cross region restore, public network configuration, identity settings, and monitoring.
* Supports enabling private endpoints for backups and site recovery.
* Support customer's managed key for encryption (cmk)
* Support custom backup policies. File share policy, workload policy, virtual machine policy

## Limitations and notes

* Feature in preview: Using `user-assigned managed identities` still in preview. [reference](https://learn.microsoft.com/en-us/azure/backup/encryption-at-rest-with-cmk?tabs=portal#assign-a-user-assigned-managed-identity-to-the-vault-in-preview)
* Vaults that use `user-assigned managed identities` for CMK encryption don't support the use of private endpoints for backup. [reference](https://learn.microsoft.com/en-us/azure/backup/)

## Feature requests and work in progress

* Azure site recovery fabric
* Azure site recovery containers
* Azure site recovery network mapping
* Azure site recovery custom policies
* Azure site recovery virtual machine replication
* Azure site recovery plan

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
