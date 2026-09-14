output "resource" {
  description = "The protected virtual machine resource."
  value       = azapi_resource.this
}

output "resource_id" {
  description = "The resource ID of the protected virtual machine."
  value       = azapi_resource.this.id
}

output "protection_state" {
  description = "The protection state returned by Azure Backup."
  value       = try(azapi_resource.this.output.properties.protectionState, null)
}
