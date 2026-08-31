output "body" {
  description = "The configured AzAPI request body sent to Azure for the Azure Files protected item."
  value       = azapi_resource.this.body
}

output "name" {
  description = "The name of the Azure Files protected item."
  value       = azapi_resource.this.name
}

output "parent_id" {
  description = "The ARM resource ID of the protection container that contains the Azure Files protected item."
  value       = azapi_resource.this.parent_id
}

output "policy_id" {
  description = "The ARM resource ID of the backup policy applied to the Azure Files protected item."
  value       = data.azapi_resource.this.id
}

output "protection_container_resource_id" {
  description = "The ARM resource ID of the storage account protection container registered with the vault, or `null` when registration is disabled."
  value       = try(azapi_resource.storage_container[0].id, null)
}

output "resource_id" {
  description = "The ARM resource ID of the Azure Files protected item."
  value       = azapi_resource.this.id
}
