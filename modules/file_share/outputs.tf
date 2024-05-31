# output "id" {
#   value = [for key, value in azurerm_backup_policy_vm_workload.this: 
#              value.id
#            ] 
# }
# output "name" {
#   value = [for key, value in azurerm_backup_policy_vm_workload.this: 
#              value.name
#            ] 
# }
# output "policy" {
#   value = azurerm_backup_policy_vm_workload.this
# }