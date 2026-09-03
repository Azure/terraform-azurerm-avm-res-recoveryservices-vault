locals {
  source_vm_name                = basename(var.backup_protected_vm.source_vm_id)
  source_vm_resource_group_name = split("/", var.backup_protected_vm.source_vm_id)[4]
}
