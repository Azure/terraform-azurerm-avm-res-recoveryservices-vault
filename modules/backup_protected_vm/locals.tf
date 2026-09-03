locals {
  # The Azure Backup fabric that hosts Azure IaaS VM containers is always named "Azure".
  backup_fabric_name = "Azure"
  # The source virtual machine ID is the only input we get, so the container and
  # protected item names are derived from it. Azure Backup uses a fixed, documented
  # naming scheme for Azure Resource Manager IaaS VMs:
  #   container      : IaasVMContainer;iaasvmcontainerv2;<vm resource group>;<vm name>
  #   protected item : VM;iaasvmcontainerv2;<vm resource group>;<vm name>
  source_vm               = provider::azapi::parse_resource_id("Microsoft.Compute/virtualMachines", var.backup_protected_vm.source_vm_id)
  container_name          = "IaasVMContainer;iaasvmcontainerv2;${local.source_vm.resource_group_name};${local.source_vm.name}"
  protected_item_name     = "VM;iaasvmcontainerv2;${local.source_vm.resource_group_name};${local.source_vm.name}"
  protection_container_id = "${local.vault_id}/backupFabrics/${local.backup_fabric_name}/protectionContainers/${local.container_name}"
  # The root module only passes the vault name and its resource group, so the vault
  # ARM ID is rebuilt here from the current AzAPI client configuration.
  vault_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/resourceGroups/${var.backup_protected_vm.vault_resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.backup_protected_vm.vault_name}"
}
