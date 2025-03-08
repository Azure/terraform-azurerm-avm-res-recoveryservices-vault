
locals {
  policies = { 
    
    # for top_key, top_value in var.site_recovery_fabric_mapping.policies:
    # top_key => top_value
    # if var.site_recovery_fabric_mapping == null
  }
  fabrics = { 
    # for top_key, top_value in var.site_recovery_fabric_mapping.fabrics:
    # top_key => top_value
    # if var.site_recovery_fabric_mapping.fabrics != null
  }
  network_mapping = { 
    # for top_key, top_value in var.site_recovery_fabric_mapping.network_mapping:
    # top_key => top_value
    # if var.site_recovery_fabric_mapping.network_mapping != null
  }
  create_policies = merge(try(var.site_recovery_policies, null), try(var.site_recovery_fabric_mapping.policies, null))
  create_fabrics = merge(try(var.site_recovery_fabrics, {}), try(var.site_recovery_fabric_mapping.fabrics, {})) # local.fabrics)
  create_mapping = merge(try(var.site_recovery_network_mapping, {}), try(var.site_recovery_fabric_mapping.network_mapping, {})) # local.network_mapping)
  output_fabrics = {for top_key, top_value in merge(module.site_recovery_fabric, module.site_recovery_fabric_container): 
                      top_key => top_value["resource"] 
                      # if top_value["resource"].name == "fab-centralus-s2"
                    }
}
output "backup_protected_file_share" {
  value = module.backup_protected_file_share
}

# resource "azurerm_backup_container_storage_account" "this" {


#   for_each = try(var.backup_protected_file_share != null ? var.backup_protected_file_share : {}) 

#   resource_group_name       = azurerm_recovery_services_vault.this.resource_group_name
#   recovery_vault_name       = azurerm_recovery_services_vault.this.name
#   storage_account_id  = each.value.source_storage_account_id
#   timeouts {
#     create = "60m"
#     delete = "60m"
#     read   = "10m"
#   }
  
# }
module "backup_protected_vm" {
  source = "./modules/backup_protected_vm"

  for_each = try(var.backup_protected_vm != null ? var.backup_protected_vm : {})
  backup_protected_vm = {
    source_vm_id = each.value.source_vm_id
    vm_backup_policy_name = each.value.vm_backup_policy_name
    vault_name = azurerm_recovery_services_vault.this.name
    vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
  }
}

module "backup_protected_file_share" {
  
  source = "./modules/backup_protected_file_share"

  for_each = try(var.backup_protected_file_share != null ? var.backup_protected_file_share : {}) 
    backup_protected_file_share = {
      vault_name = azurerm_recovery_services_vault.this.name
      vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
      source_storage_account_id = each.value.source_storage_account_id
      source_file_share_name    = each.value.source_file_share_name
      backup_file_share_policy_name          = each.value.backup_file_share_policy_name
      disable_registration = false
      sleep_timer = each.value.sleep_timer

    }

    depends_on = [ module.recovery_services_vault_file_share_policy, ] #azurerm_backup_container_storage_account.this ]

}
  module "site_recovery_network_mapping" {

    source = "./modules/site_recovery_network_mapping"

    for_each = try(var.site_recovery_network_mapping != null ? var.site_recovery_network_mapping : {}) 
    
    site_recovery_network_mapping = {
      name = each.value.name
      vault_name = azurerm_recovery_services_vault.this.name
      vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
      source_recovery_fabric_name = each.value.source_recovery_fabric_name
      target_recovery_fabric_name = each.value.target_recovery_fabric_name
      source_network_id = each.value.source_network_id
      target_network_id = each.value.target_network_id
        sleep_timer = each.value.sleep_timer
    }    
    
    depends_on = [ module.site_recovery_fabric_container, module.site_recovery_policies ]

  }

module "site_recovery_fabric" {
  source = "./modules/site_recovery_fabric"

  for_each = try(var.site_recovery_fabrics != null ? var.site_recovery_fabrics : {}) 
  
    site_recovery_fabric = {
        name = each.value.fabric_name
        location = each.value.location
        vault_name = azurerm_recovery_services_vault.this.name
        vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
        sleep_timer = each.value.sleep_timer
    }

  # depends_on = [ time_sleep.wait_seconds_site_recovery ]

}

module "site_recovery_fabric_container" {
    depends_on = [ module.site_recovery_fabric, ]
  source = "./modules/site_recovery_fabric_container"

  for_each = try(var.site_recovery_fabrics != null ? var.site_recovery_fabrics : {}) 
    site_recovery_fabric_container = {
        name = each.value.container_name
        fabric_name = each.value.fabric_name
        location = each.value.location
        vault_name = azurerm_recovery_services_vault.this.name
        vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
        sleep_timer = each.value.sleep_timer

    }

}

module "site_recovery_policies" {
  source = "./modules/site_recovery_policy"

  for_each = local.create_policies != null ? local.create_policies : {}

  site_recovery_policy = {
    name                                                 = each.value.name
    resource_group_name  = azurerm_recovery_services_vault.this.resource_group_name
    recovery_vault_name  = azurerm_recovery_services_vault.this.name
    recovery_point_retention_in_minutes                  = each.value.recovery_point_retention_in_minutes
    application_consistent_snapshot_frequency_in_minutes = each.value.application_consistent_snapshot_frequency_in_minutes
        sleep_timer = each.value.sleep_timer

  }
}

module "site_recovery_fabric_mapping" {

  source = "./modules/site_recovery_fabric_mapping"

  for_each = try(var.site_recovery_fabric_mapping != null ? var.site_recovery_fabric_mapping : {}) 
  
    fabric_mapping = {
      name                                      = each.value.name
      vault_name = azurerm_recovery_services_vault.this.name
      vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
      recovery_source_fabric_name                      = each.value.recovery_source_fabric_name 
      recovery_source_protection_container_name = each.value.recovery_source_protection_container_name
      recovery_target_protection_container_id   = module.site_recovery_fabric_container[each.value.recovery_targe_protection_container_name].resource.id
      recovery_replication_policy_id            = module.site_recovery_policies[each.value.recovery_replication_policy_name].resource.id
        sleep_timer = each.value.sleep_timer
    }
}
/*
output "taget_container_id_westus" {
  value = module.site_recovery_fabric_container["eastus"].resource.id
}


module "backup_protected_vm" {
  source = "./modules/backup_protected_vm"

  for_each = try(var.site_recovery_backup_protected_vm != null ? var.site_recovery_backup_protected_vm : {})
  backup_protected_vm = {
    source_vm_id = each.value.source_vm_id
    backup_policy_id = each.value.backup_policy_id
    vault_name = azurerm_recovery_services_vault.this.name
    vault_resource_group_name = azurerm_recovery_services_vault.this.resource_group_name
  }
}

  output "policy_id" {
    value = [for top_key, top_value in module.site_recovery_policies: 
              top_value["resource"].id 
              if top_value["resource"].name == "pol-westus2-to-centralus-s2"
            ] 
  }

  output "containers" {
    value = [for top_key, top_value in module.site_recovery_fabric_container: 
              top_value["resource"].id 
              if top_value["resource"].name == "con-westus-s1"
            ]
  }
  output "fabrics" {
    value = [for top_key, top_value in module.site_recovery_fabric: 
              top_value["resource"].id 
              if top_value["resource"].name == "fab-westus-s1"
            ]
  }
*/