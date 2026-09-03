output "body" {
  description = "The configured AzAPI request body sent to Azure for the Azure Site Recovery replication protected item."
  value       = azapi_resource.this.body
}

output "name" {
  description = "The name of the Azure Site Recovery replication protected item."
  value       = azapi_resource.this.name
}

output "parent_id" {
  description = "The ARM resource ID of the source replication protection container that contains the replication protected item."
  value       = azapi_resource.this.parent_id
}

output "resource_id" {
  description = "The ARM resource ID of the Azure Site Recovery replication protected item."
  value       = azapi_resource.this.id
}
