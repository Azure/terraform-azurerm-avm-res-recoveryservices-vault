module "this" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.6"

  location                 = azurerm_resource_group.primary.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.primary.name
  account_kind             = "StorageV2"
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  azure_files_authentication = {
    default_share_level_permission = "StorageFileDataSmbShareReader"
    directory_type                 = "AADKERB"
  }
  blob_properties = {
    versioning_enabled = true
  }
  https_traffic_only_enabled = true
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this_identity.id]
  }
  min_tls_version = "TLS1_2"
  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = [] # [try(module.public_ip[0].public_ip, var.bypass_ip_cidr)]
    virtual_network_subnet_ids = [] # toset([azurerm_subnet.private.id])
  }
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  tags = {
    env   = "Dev"
    owner = "John Doe"
    dept  = "IT"
  }
}