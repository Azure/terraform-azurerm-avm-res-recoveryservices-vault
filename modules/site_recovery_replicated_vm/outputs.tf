output "resource" {
  description = "The site recovery replicated VM resource"
  value       = azapi_resource_action.this
}

output "resource_id" {
  description = "The resource ID of the site recovery replicated VM"
  value       = local.resource_id
}

output "replication_health" {
  description = "The replication health returned by Azure Site Recovery."
  value       = try(azapi_resource_action.this.output.properties.replicationHealth, null)
}
