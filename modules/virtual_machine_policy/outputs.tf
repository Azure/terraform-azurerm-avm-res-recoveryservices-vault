output "body" {
  description = "The configured AzAPI request body sent to Azure for the virtual machine backup policy."
  value       = azapi_resource.this.body
}

output "name" {
  description = "The name of the virtual machine backup policy."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The resource ID of the virtual machine backup policy."
  value       = azapi_resource.this.id
}
