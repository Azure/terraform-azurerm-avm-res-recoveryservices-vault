output "body" {
  description = "The configured AzAPI request body sent to Azure for the Azure Backup protected item."
  value       = azapi_resource.this.body
}

output "name" {
  description = "The name of the Azure Backup protected item."
  value       = azapi_resource.this.name
}

output "parent_id" {
  description = "The ARM resource ID of the protection container that contains the Azure Backup protected item."
  value       = azapi_resource.this.parent_id
}

output "policy_id" {
  description = "The ARM resource ID of the backup policy applied to the Azure Backup protected item."
  value       = data.azapi_resource.this.id
}

output "resource_id" {
  description = "The ARM resource ID of the Azure Backup protected item."
  value       = azapi_resource.this.id
}
