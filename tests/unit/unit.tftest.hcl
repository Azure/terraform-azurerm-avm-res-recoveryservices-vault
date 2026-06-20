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
# To run (using the ./avm wrapper script at the repository root, which runs
# commands inside the AVM-managed container):
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

mock_provider "azurerm" {
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/pe-test"
    }
  }
}
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

# ---------------------------------------------------------------------------
# run: cmk_requires_managed_identity
#
# CMK encryption requires a managed identity configuration.
# ---------------------------------------------------------------------------
run "cmk_requires_managed_identity" {
  command = plan

  variables {
    customer_managed_key = {
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      key_name              = "https://kv-test.vault.azure.net/keys/key1/00000000000000000000000000000000"
    }
  }

  expect_failures = [var.customer_managed_key]
}

# ---------------------------------------------------------------------------
# run: cmk_allows_system_assigned_identity
#
# CMK should be allowed without customer_managed_key.user_assigned_identity
# when the vault has a system-assigned managed identity enabled.
# ---------------------------------------------------------------------------
run "cmk_allows_system_assigned_identity" {
  command = plan

  variables {
    managed_identities = {
      system_assigned = true
    }
    customer_managed_key = {
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      key_name              = "https://kv-test.vault.azure.net/keys/key1/00000000000000000000000000000000"
    }
  }
}

# ---------------------------------------------------------------------------
# run: cmk_allows_user_assigned_identity_when_attached
#
# CMK should be allowed when a user-assigned identity is provided and that same
# identity is attached to the vault via managed_identities.user_assigned_resource_ids.
# ---------------------------------------------------------------------------
run "cmk_allows_user_assigned_identity_when_attached" {
  command = plan

  variables {
    managed_identities = {
      user_assigned_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-test"
      ]
    }
    customer_managed_key = {
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      key_name              = "https://kv-test.vault.azure.net/keys/key1/00000000000000000000000000000000"
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-test"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# run: cmk_user_assigned_identity_must_be_attached
#
# If customer_managed_key.user_assigned_identity is provided, it must also be
# listed in managed_identities.user_assigned_resource_ids.
# ---------------------------------------------------------------------------
run "cmk_user_assigned_identity_must_be_attached" {
  command = plan

  variables {
    customer_managed_key = {
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      key_name              = "https://kv-test.vault.azure.net/keys/key1/00000000000000000000000000000000"
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-test"
      }
    }
  }

  expect_failures = [var.customer_managed_key]
}

# ---------------------------------------------------------------------------
# run: import_null_identity_ignored
#
# Verifies that the vault resource sets ignore_null_property = true so that
# a null `identity` in the body (when no managed identity is configured) is
# not treated as "remove identity" during plan/apply.
#
# Without this setting, importing a vault whose identity was set or
# auto-assigned by Azure would produce a PUT body without the identity field,
# causing a 400 ManagedIdentityDetailsNotPresent error from the Azure API.
# ---------------------------------------------------------------------------
run "import_null_identity_ignored" {
  command = apply

  assert {
    condition     = azapi_resource.this.ignore_null_property == true
    error_message = "ignore_null_property must be true so that a null identity body property is not treated as a request to remove Azure-assigned identities. Without this, importing a vault causes a 400 ManagedIdentityDetailsNotPresent error."
  }
}

# ---------------------------------------------------------------------------
# run: soft_delete_enabled_by_default
#
# The default soft delete state must be "Enabled".
# ---------------------------------------------------------------------------
run "soft_delete_enabled_by_default" {
  command = apply

  assert {
    condition     = azapi_resource.this.body.properties.securitySettings.softDeleteSettings.softDeleteState == "Enabled"
    error_message = "Soft delete state should default to 'Enabled'."
  }
}

# ---------------------------------------------------------------------------
# run: soft_delete_disabled
#
# Verifies that soft delete can be set to "Disabled".
# ---------------------------------------------------------------------------
run "soft_delete_disabled" {
  command = apply

  variables {
    soft_delete_enabled = "Disabled"
  }

  assert {
    condition     = azapi_resource.this.body.properties.securitySettings.softDeleteSettings.softDeleteState == "Disabled"
    error_message = "Soft delete state should be 'Disabled' when set to 'Disabled'."
  }
}

# ---------------------------------------------------------------------------
# run: soft_delete_always_on
#
# Verifies that the "AlwaysOn" always-on soft delete state can be configured.
# ---------------------------------------------------------------------------
run "soft_delete_always_on" {
  command = apply

  variables {
    soft_delete_enabled = "AlwaysOn"
  }

  assert {
    condition     = azapi_resource.this.body.properties.securitySettings.softDeleteSettings.softDeleteState == "AlwaysOn"
    error_message = "Soft delete state should be 'AlwaysON' when always-on soft delete is enabled."
  }
}

# ---------------------------------------------------------------------------
# run: soft_delete_invalid_value
#
# Verifies that an invalid value for soft_delete_enabled is rejected.
# ---------------------------------------------------------------------------
run "soft_delete_invalid_value" {
  command = plan

  variables {
    soft_delete_enabled = "Invalid"
  }

  expect_failures = [var.soft_delete_enabled]
}

# ---------------------------------------------------------------------------
# run: resource_guard_operation_requests_applied
#
# Verifies that Resource Guard operation request IDs are passed through to the
# vault properties when supplied.
# ---------------------------------------------------------------------------
run "resource_guard_operation_requests_applied" {
  command = apply

  variables {
    resource_guard_operation_requests = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-guard/providers/Microsoft.DataProtection/resourceGuards/rg1/modifyEncryptionSettings/default"
    ]
  }

  assert {
    condition     = length(azapi_resource.this.body.properties.resourceGuardOperationRequests) == 1
    error_message = "Expected one Resource Guard operation request ID to be set on the vault properties."
  }

  assert {
    condition     = azapi_resource.this.body.properties.resourceGuardOperationRequests[0] == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-guard/providers/Microsoft.DataProtection/resourceGuards/rg1/modifyEncryptionSettings/default"
    error_message = "The supplied Resource Guard operation request ID should be passed through unchanged."
  }
}

# ---------------------------------------------------------------------------
# run: unmanaged_private_endpoints_omit_dns_zone_group
#
# When callers manage private DNS zone groups outside the module, the private
# endpoint resource must omit the inline private_dns_zone_group block entirely.
# This avoids update calls that can fail for Recovery Services Vault private
# endpoints when centrally managed DNS zone groups are attached separately.
# ---------------------------------------------------------------------------
run "unmanaged_private_endpoints_omit_dns_zone_group" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      backup = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name              = "AzureBackup"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.test.windowsazure.com"]
        application_security_group_associations = {
          asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationSecurityGroups/asg-test"
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0
    error_message = "Managed private endpoint resources should not be created when var.private_endpoints_manage_dns_zone_group is false."
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 1
    error_message = "Exactly one unmanaged private endpoint should be created when DNS zone groups are managed externally."
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["backup"].private_dns_zone_group) == 0
    error_message = "Unmanaged private endpoints must omit the inline private_dns_zone_group block even when private DNS zone IDs are supplied."
  }

  assert {
    condition     = can(azurerm_private_endpoint_application_security_group_association.this["backup-asg"])
    error_message = "Private endpoint ASG associations must target the unmanaged private endpoint resource when DNS zone groups are managed externally."
  }
}

# ---------------------------------------------------------------------------
# run: managed_private_endpoints_include_dns_zone_group
#
# When the module manages private DNS zone groups (default), the managed
# private endpoint resource must be created and must include the inline
# private_dns_zone_group block when DNS zone IDs are supplied.  The unmanaged
# resource must be absent.
#
# This complements the unmanaged_private_endpoints_omit_dns_zone_group test
# and ensures the two exclusive resource types are not created concurrently,
# which would trigger overlapping ARM operations on the same
# privateDnsZoneGroups/default resource (CanceledAndSupersededDueToAnotherOperation).
# ---------------------------------------------------------------------------
run "managed_private_endpoints_include_dns_zone_group" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      backup = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name              = "AzureBackup"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.test.windowsazure.com"]
      }
    }
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 1
    error_message = "Exactly one managed private endpoint should be created when var.private_endpoints_manage_dns_zone_group is true."
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0
    error_message = "Unmanaged private endpoint resources must not be created when var.private_endpoints_manage_dns_zone_group is true."
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_managed_dns_zone_groups["backup"].private_dns_zone_group) == 1
    error_message = "Managed private endpoints must include the inline private_dns_zone_group block when private DNS zone IDs are supplied."
  }
}

run "managed_private_endpoints_sequence_and_unique_defaults" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = true
    private_endpoints = {
      backup = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name              = "AzureBackup"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.test.windowsazure.com"]
      }
      site_recovery = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name              = "AzureSiteRecovery"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.siterecovery.windowsazure.com"]
      }
    }

  }

  assert {
    condition     = azurerm_private_endpoint.this_managed_dns_zone_groups["backup"].name == "pep-${var.name}-backup" && azurerm_private_endpoint.this_managed_dns_zone_groups["site_recovery"].name == "pep-${var.name}-site_recovery"
    error_message = "When multiple managed private endpoints are configured without explicit names, default names must include the map key to avoid collisions."
  }

  assert {
    condition     = azurerm_private_endpoint.this_managed_dns_zone_groups["backup"].private_service_connection[0].name == "pse-${var.name}-backup" && azurerm_private_endpoint.this_managed_dns_zone_groups["site_recovery"].private_service_connection[0].name == "pse-${var.name}-site_recovery"
    error_message = "When multiple managed private endpoints are configured without explicit private service connection names, defaults must include the map key to avoid collisions."
  }
}

run "workload_daily_full_uses_retention_weekly_monthly_yearly_config" {
  command = apply

  variables {
    workload_backup_policy = {
      daily_full = {
        name          = "pol-rsv-saph-vault-01"
        workload_type = "SAPHanaDatabase"
        settings = {
          time_zone           = "Pacific Standard Time"
          compression_enabled = false
        }
        backup_frequency = "Daily"
        protection_policy = {
          full = {
            policy_type           = "Full"
            retention_daily_count = 15
            backup = {
              time     = "22:00"
              weekdays = ["Monday"]
            }
            retention_weekly = {
              count    = 10
              weekdays = ["Saturday"]
            }
            retention_monthly = {
              count    = 10
              weekdays = ["Saturday"]
              weeks    = ["First"]
            }
            retention_yearly = {
              count    = 10
              months   = ["January"]
              weekdays = ["Sunday"]
              weeks    = ["Last"]
            }
          }
        }
      }
    }
  }

  assert {
    condition     = module.recovery_workload_policy["daily_full"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.weeklySchedule != null
    error_message = "weeklySchedule should be set when retention_weekly is configured, even when backup_frequency is Daily."
  }

  assert {
    condition     = contains(module.recovery_workload_policy["daily_full"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.monthlySchedule.retentionScheduleWeekly.daysOfTheWeek, "Saturday") && !contains(module.recovery_workload_policy["daily_full"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.monthlySchedule.retentionScheduleWeekly.daysOfTheWeek, "Monday")
    error_message = "Monthly retention weekly days should come from retention_monthly.weekdays, not backup.weekdays."
  }

  assert {
    condition     = module.recovery_workload_policy["daily_full"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.monthlySchedule.retentionScheduleFormatType == "Weekly"
    error_message = "Monthly retention schedule format should be Weekly when retention_monthly.weekdays is set."
  }

  assert {
    condition     = contains(module.recovery_workload_policy["daily_full"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.yearlySchedule.retentionScheduleWeekly.daysOfTheWeek, "Sunday") && !contains(module.recovery_workload_policy["daily_full"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.yearlySchedule.retentionScheduleWeekly.daysOfTheWeek, "Monday")
    error_message = "Yearly retention weekly days should come from retention_yearly.weekdays, not backup.weekdays."
  }

  assert {
    condition     = module.recovery_workload_policy["daily_full"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.yearlySchedule.retentionScheduleFormatType == "Weekly"
    error_message = "Yearly retention schedule format should be Weekly when retention_yearly.weekdays is set."
  }
}

run "workload_daily_full_uses_monthdays_for_daily_monthly_yearly_retention" {
  command = apply

  variables {
    workload_backup_policy = {
      daily_full_monthdays = {
        name          = "pol-rsv-saph-vault-02"
        workload_type = "SAPHanaDatabase"
        settings = {
          time_zone           = "Pacific Standard Time"
          compression_enabled = false
        }
        backup_frequency = "Daily"
        protection_policy = {
          full = {
            policy_type           = "Full"
            retention_daily_count = 15
            backup = {
              time = "22:00"
            }
            retention_monthly = {
              count     = 10
              monthdays = [3, 10]
            }
            retention_yearly = {
              count     = 10
              months    = ["January"]
              monthdays = [20]
            }
          }
        }
      }
    }
  }

  assert {
    condition     = module.recovery_workload_policy["daily_full_monthdays"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.monthlySchedule.retentionScheduleFormatType == "Daily"
    error_message = "Monthly retention schedule format should be Daily when retention_monthly.monthdays is set."
  }

  assert {
    condition     = module.recovery_workload_policy["daily_full_monthdays"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.monthlySchedule.retentionScheduleWeekly == null
    error_message = "Monthly retention weekly schedule should be null when retention_monthly.weekdays is not set."
  }

  assert {
    condition     = module.recovery_workload_policy["daily_full_monthdays"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.yearlySchedule.retentionScheduleFormatType == "Daily"
    error_message = "Yearly retention schedule format should be Daily when retention_yearly.monthdays is set."
  }

  assert {
    condition     = module.recovery_workload_policy["daily_full_monthdays"].resource.body.properties.subProtectionPolicy[0].retentionPolicy.yearlySchedule.retentionScheduleWeekly == null
    error_message = "Yearly retention weekly schedule should be null when retention_yearly.weekdays is not set."
  }
}

# ---------------------------------------------------------------------------
# run: file_share_hourly_policy_parses_without_error
#
# Regression test for the v1.1.8 duplicate `is_hourly` local bug in
# modules/file_share_policy/main.tf.  On the buggy code Terraform would emit
# "Attribute redefined" and refuse to plan; the fix removes the duplicate.
# This run exercises the hourly path end-to-end and verifies that:
#   - the schedule policy type is set to Hourly
#   - the hourlySchedule block is populated with the configured interval
# ---------------------------------------------------------------------------
run "file_share_hourly_policy_parses_without_error" {
  command = apply

  variables {
    file_share_backup_policy = {
      hourly = {
        name      = "pol-rsv-fileshare-hourly-001"
        timezone  = "UTC"
        frequency = "Hourly"
        backup = {
          time = "06:00"
          hourly = {
            interval        = 4
            start_time      = "06:00"
            window_duration = 12
          }
        }
        retention_daily = 7
      }
    }
  }

  assert {
    condition     = module.recovery_services_vault_file_share_policy["hourly"].resource.body.properties.schedulePolicy.scheduleRunFrequency == "Hourly"
    error_message = "scheduleRunFrequency should be Hourly for an hourly file share backup policy."
  }

  assert {
    condition     = module.recovery_services_vault_file_share_policy["hourly"].resource.body.properties.schedulePolicy.hourlySchedule.interval == 4
    error_message = "hourlySchedule.interval should match the configured backup interval."
  }

  assert {
    condition     = module.recovery_services_vault_file_share_policy["hourly"].resource.body.properties.schedulePolicy.hourlySchedule.scheduleWindowDuration == 12
    error_message = "hourlySchedule.scheduleWindowDuration should match the configured window_duration."
  }
}
