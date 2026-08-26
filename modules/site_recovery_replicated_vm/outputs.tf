output "resource" {
  description = "The `azapi_resource` object for the Azure Site Recovery replication protected item (`Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectedItems`). This is an AzAPI resource object, not the legacy AzureRM `azurerm_site_recovery_replicated_vm` object."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The ARM resource ID of the Azure Site Recovery replication protected item."
  value       = azapi_resource.this.id
}
