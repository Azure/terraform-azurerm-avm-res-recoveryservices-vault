output "resource_group_location" {
  value = azurerm_resource_group.this.location
}
output "short_region" {
  value = module.azure_region.location_short
}
# output "regions" {
#   value = module.regions.regions
# }