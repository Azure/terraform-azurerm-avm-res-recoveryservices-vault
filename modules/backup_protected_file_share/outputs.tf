output "resource" {
  description = "The protected file share resource."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the protected file share."
  value       = azapi_resource.this.id
}

output "protection_container_id" {
  description = "The resource ID of the storage protection container."
  value       = var.parent_id
}

output "protection_state" {
  description = "The protection state returned by Azure Backup."
  value       = try(azapi_resource.this.output.properties.protectionState, null)
}
