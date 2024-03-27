# terraform-azurerm-avm-recoveryservices-vault

This terraform module is designed to deploy Azure Recovery Services Vault. It has support to create private link private endpoints to make the resource privately accessible via customer's private virtual networks and use a customer managed encryption key.

## Features

* Create an Azure recovery services vault resource with options such as immutability, soft delete, storage type, cross region restore, public network configuration, identity settings, and monitoring.
* Supports enabling private endpoints for backups and site recovery.
* Support customer's managed key for encryption (cmk)
