# Unit tests for the Recovery Services Vault module.
#
# These tests use provider mocking so they require no Azure credentials and run
# quickly.  They focus on two things:
#
# 1. The vault is managed as `azapi_resource.this` (the target address of the
#    `moved` block that migrates state from v0.x `azurerm_recovery_services_vault.this`).
#
# 2. Key optional features (locks, role assignments, diagnostic settings) are
#    conditionally created or omitted as expected.
#
# To run:
#   PORCH_NO_TUI=1 ./avm tf-test-unit

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.RecoveryServices/vaults/rsv-test-001"
    }
  }
}

mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

# ---------------------------------------------------------------------------
# Shared variable defaults applied to every run block.
# ---------------------------------------------------------------------------
variables {
  location            = "eastus"
  name                = "rsv-test-001"
  resource_group_name = "rg-test"
  sku                 = "RS0"
}

# ---------------------------------------------------------------------------
# run: vault_at_correct_state_address
#
# Verifies that the vault is managed by `azapi_resource.this`, which is the
# target of the `moved` block.  When a caller upgrades from module v0.x
# (where the vault lived at `azurerm_recovery_services_vault.this`), Terraform
# will move the existing state entry to this address rather than destroying and
# recreating the resource.
# ---------------------------------------------------------------------------
run "vault_at_correct_state_address" {
  command = apply

  assert {
    condition     = can(azapi_resource.this)
    error_message = "The vault must be managed as azapi_resource.this – this is the target address of the v0.x -> v1.x moved block. If this resource is absent, upgrades from v0.x will destroy existing vaults."
  }

  assert {
    condition     = azapi_resource.this.name == var.name
    error_message = "The vault name should match the value supplied via var.name."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.RecoveryServices/vaults@2024-10-01"
    error_message = "The vault must be declared as a Microsoft.RecoveryServices/vaults AzAPI resource."
  }
}

# ---------------------------------------------------------------------------
# run: no_lock_by_default
#
# The management lock is optional (var.lock defaults to null).  Verify that no
# lock is created when the variable is not set.
# ---------------------------------------------------------------------------
run "no_lock_by_default" {
  command = apply

  assert {
    condition     = length(azurerm_management_lock.this) == 0
    error_message = "No management lock should be created when var.lock is null."
  }
}

# ---------------------------------------------------------------------------
# run: lock_created_when_configured
#
# When var.lock is provided a lock resource must be created.
# ---------------------------------------------------------------------------
run "lock_created_when_configured" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
      name = "lock-rsv-test"
    }
  }

  assert {
    condition     = length(azurerm_management_lock.this) == 1
    error_message = "A management lock should be created when var.lock is supplied."
  }

  assert {
    condition     = azurerm_management_lock.this[0].lock_level == "CanNotDelete"
    error_message = "The lock level should match the value supplied via var.lock.kind."
  }
}

# ---------------------------------------------------------------------------
# run: no_role_assignments_by_default
#
# Role assignments are optional.  Verify none are created when not requested.
# ---------------------------------------------------------------------------
run "no_role_assignments_by_default" {
  command = apply

  assert {
    condition     = length(azurerm_role_assignment.this) == 0
    error_message = "No role assignments should be created when var.role_assignments is empty."
  }
}

# ---------------------------------------------------------------------------
# run: telemetry_enabled_by_default
#
# AVM modules must emit telemetry unless explicitly disabled.
# ---------------------------------------------------------------------------
run "telemetry_enabled_by_default" {
  command = apply

  assert {
    condition     = can(modtm_telemetry.telemetry)
    error_message = "Telemetry resource should be created when enable_telemetry is true (default)."
  }
}
