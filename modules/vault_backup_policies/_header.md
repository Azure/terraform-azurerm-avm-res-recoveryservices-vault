# terraform-azurerm-avm-recoveryservices-vault

This terraform module is designed to deploy Azure Recovery Services Vault. It has support to create private link private endpoints to make the resource privately accessible via customer's private virtual networks and use a customer managed encryption key.

## Features

* Create an Azure recovery services vault resource with options such as immutability, soft delete, storage type, cross region restore, public network configuration, identity settings, and monitoring.
* Supports enabling private endpoints for backups and site recovery.
* Support customer's managed key for encryption (cmk)

## Limitations and notes

* Feature in preview: Using `user-assigned managed identities` still in preview. [reference](https://learn.microsoft.com/en-us/azure/backup/encryption-at-rest-with-cmk?tabs=portal#assign-a-user-assigned-managed-identity-to-the-vault-in-preview)
  * Vaults that use `user-assigned managed identities` for CMK encryption don't support the use of private endpoints for backup. [reference](https://learn.microsoft.com/en-us/azure/backup/)
