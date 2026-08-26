resource "azapi_resource" "storage_account" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = module.naming.storage_account.name_unique
  parent_id = azapi_resource.resource_group_primary.id
  location  = azapi_resource.resource_group_primary.location

  body = {
    identity = {
      type = "SystemAssigned,UserAssigned"
      userAssignedIdentities = {
        (azapi_resource.user_assigned_identity.id) = {}
      }
    }
    kind = "StorageV2"
    properties = {
      allowSharedKeyAccess     = true
      minimumTlsVersion        = "TLS1_2"
      publicNetworkAccess      = "Disabled"
      supportsHttpsTrafficOnly = true
      azureFilesIdentityBasedAuthentication = {
        defaultSharePermission  = "StorageFileDataSmbShareReader"
        directoryServiceOptions = "AADKERB"
      }
      networkAcls = {
        bypass              = "AzureServices"
        defaultAction       = "Deny"
        ipRules             = []
        virtualNetworkRules = []
      }
    }
    sku = {
      name = "Standard_ZRS"
    }
  }

  response_export_values = ["*"]
  tags = {
    env   = "Dev"
    owner = "John Doe"
    dept  = "IT"
  }
}

resource "azapi_resource" "storage_account_blob_service" {
  type      = "Microsoft.Storage/storageAccounts/blobServices@2023-05-01"
  name      = "default"
  parent_id = azapi_resource.storage_account.id

  body = {
    properties = {
      isVersioningEnabled = true
    }
  }

  response_export_values = ["*"]
}
