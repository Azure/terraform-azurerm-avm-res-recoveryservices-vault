module "this" {

  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.6"

  account_replication_type = "ZRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"

  location                      = azurerm_resource_group.primary.location
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.primary.name
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
  shared_access_key_enabled     = true
  public_network_access_enabled = true
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this_identity.id]
  }
  azure_files_authentication = {
    default_share_level_permission = "StorageFileDataSmbShareReader"
    directory_type                 = "AADKERB"
  }
  tags = {
    env   = "Dev"
    owner = "John Doe"
    dept  = "IT"
  }
  blob_properties = {
    versioning_enabled = true
  }
  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = [] # [try(module.public_ip[0].public_ip, var.bypass_ip_cidr)]
    virtual_network_subnet_ids = [] # toset([azurerm_subnet.private.id])
  }
  /*

  role_assignments = {
    role_assignment_1 = {
      role_definition_id_or_name       = data.azurerm_role_definition.example.name
      principal_id                     = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
      skip_service_principal_aad_check = false
    },
    role_assignment_2 = {
      role_definition_id_or_name       = "Owner"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    },

  }
  containers = {
    blob_container0 = {
      name                  = "blob-container-${random_string.this.result}-0"
      container_access_type = "private"
    }
    blob_container1 = {
      name                  = "blob-container-${random_string.this.result}-1"
      container_access_type = "private"

    }

  }
  queues = {
    queue0 = {
      name = "queue-${random_string.this.result}-0"

    }
    queue1 = {
      name = "queue-${random_string.this.result}-1"

      metadata = {
        key1 = "value1"
        key2 = "value2"
      }
    }
  }
  tables = {
    table0 = {
      name = "table${random_string.this.result}0"
      signed_identifiers = [
        {
          id = "1"
          access_policy = {
            expiry_time = "2025-01-01T00:00:00Z"
            permission  = "r"
            start_time  = "2024-01-01T00:00:00Z"
          }
        }
      ]
    }
    table1 = {
      name = "table${random_string.this.result}1"

      signed_identifiers = [
        {
          id = "1"
          access_policy = {
            expiry_time = "2025-01-01T00:00:00Z"
            permission  = "r"
            start_time  = "2024-01-01T00:00:00Z"
          }
        }
      ]
    }
  }

  shares = {
    share0 = {
      name  = "share-${random_string.this.result}-0"
      quota = 10
      signed_identifiers = [
        {
          id = "1"
          access_policy = {
            expiry_time = "2025-01-01T00:00:00Z"
            permission  = "r"
            start_time  = "2024-01-01T00:00:00Z"
          }
        }
      ]
    }
    share1 = {
      name        = "share-${random_string.this.result}-1"
      quota       = 10
      access_tier = "Hot"
      metadata = {
        key1 = "value1"
        key2 = "value2"
      }
    }
  }
*/


}