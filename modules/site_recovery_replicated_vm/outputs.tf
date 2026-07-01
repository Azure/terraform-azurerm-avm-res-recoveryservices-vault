output "resource" {
  description = "The site recovery replicated VM resource"
  value       = azurerm_site_recovery_replicated_vm.this
}

output "resource_id" {
  description = "The resource ID of the site recovery replicated VM"
  value       = azurerm_site_recovery_replicated_vm.this.id
}
