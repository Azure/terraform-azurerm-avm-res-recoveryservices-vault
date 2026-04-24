
# Read current subscription / tenant details from the AzAPI provider config.
# subscription_id is available at plan time, which is required by the import block below.
data "azapi_client_config" "current" {}

locals {
  # Construct the full ARM resource ID from known variables and data-source values.
  # This is the correct pattern to use in an import block.
  #
  # INCORRECT (causes "Invalid import id argument" error):
  #   id = azapi_resource.vault_existing.id   ← not known until apply
  #
  # CORRECT (value is known at plan time):
  #   id = local.vault_resource_id            ← built from variables + data sources
  vault_resource_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.RecoveryServices/vaults/${var.vault_name}"
}

# ---------------------------------------------------------------------------
# Step 1 (optional) – ensure the vault exists in Azure before importing.
#
# If the vault already exists in Azure, skip this step and go straight to
# "terraform apply".
#
# If the vault does NOT yet exist, run Step 1 first:
#   terraform apply \
#     -target=azurerm_resource_group.this \
#     -target=null_resource.ensure_vault_exists
#
# Then run Step 2:
#   terraform apply
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

# Create the vault via Azure CLI so that it is available in Azure before the
# import block is processed during "terraform apply".
resource "null_resource" "ensure_vault_exists" {
  provisioner "local-exec" {
    command = <<-EOT
      az recovery-services vault create \
        --name "${var.vault_name}" \
        --resource-group "${var.resource_group_name}" \
        --location "${var.location}" \
        --sku "${var.sku}" \
        --output none 2>/dev/null \
      && echo "Vault created via CLI." \
      || echo "Vault already exists or CLI create skipped."
    EOT
  }

  depends_on = [azurerm_resource_group.this]
}

# ---------------------------------------------------------------------------
# Step 2 – import the vault into Terraform state and manage it.
#
# The import id MUST be a value known at plan time.  Using local.vault_resource_id
# (a string built from variables) satisfies this requirement, whereas using
# azapi_resource.vault_existing.id would fail with:
#
#   Error: Invalid import id argument
#   The import block "id" argument depends on resource attributes that cannot
#   be determined until apply, so Terraform cannot plan to import this resource.
# ---------------------------------------------------------------------------
import {
  id = local.vault_resource_id
  to = module.recovery_services_vault.azapi_resource.this
}

module "recovery_services_vault" {
  source = "../../"

  location                                       = azurerm_resource_group.this.location
  name                                           = var.vault_name
  resource_group_name                            = azurerm_resource_group.this.name
  sku                                            = var.sku
  alerts_for_all_job_failures_enabled            = true
  alerts_for_critical_operation_failures_enabled = true
  classic_vmware_replication_enabled             = false
  cross_region_restore_enabled                   = false
  enable_telemetry                               = var.enable_telemetry
  public_network_access_enabled                  = true
  storage_mode_type                              = "GeoRedundant"
  tags = {
    env  = "Prod"
    dept = "IT"
  }
}
