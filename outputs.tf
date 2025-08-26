output "private_endpoints" {
  description = <<DESCRIPTION
  A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource" {
  description = "resource Id output"
  value       = azurerm_recovery_services_vault.this
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource_id" {
  description = "resource Id output"
  value       = azurerm_recovery_services_vault.this.id
}

output "file_share_policy_resource_id" {
  value = module.file_share_policy.resource_id
  description = "Resource ID of the file share backup policy"
}

output "virtual_machine_policy_resource_id" {
  value = module.virtual_machine_policy.resource_id
  description = "Resource ID of the VM backup policy"
}

output "workload_policy_resource_id" {
  value = module.workload_policy.resource_id
  description = "Resource ID of the workload backup policy"
}
