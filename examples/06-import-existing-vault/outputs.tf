output "resource" {
  description = "The Recovery Services Vault resource."
  value       = module.recovery_services_vault.resource
}

output "resource_id" {
  description = "The resource ID of the Recovery Services Vault."
  value       = module.recovery_services_vault.resource_id
}
