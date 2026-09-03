output "protected_item_ids" {
  description = "A map of the protected item resource IDs, keyed by the `protected_databases` map key."
  value       = { for key, item in azapi_resource.protected_item : key => item.id }
}

output "protected_item_names" {
  description = "A map of the protected item names, keyed by the `protected_databases` map key."
  value       = { for key, item in azapi_resource.protected_item : key => item.name }
}

output "protected_items" {
  description = "A map of the protected item resources, keyed by the `protected_databases` map key."
  value       = azapi_resource.protected_item
}

output "resource" {
  description = "The registered workload protection container resource"
  value       = azapi_resource.container
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "The resource ID of the registered workload protection container"
  value       = azapi_resource.container.id
}
