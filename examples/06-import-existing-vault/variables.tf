variable "vault_name" {
  type        = string
  description = "Name of the Recovery Services Vault to import."
  default     = "rsv-import-example-006"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that contains (or will contain) the vault."
  default     = "rg-import-vault-006"
}

variable "location" {
  type        = string
  description = "Azure region where the vault is (or will be) located."
  default     = "eastus"
}

variable "sku" {
  type        = string
  description = "SKU of the Recovery Services Vault. Allowed values: RS0, Standard."
  default     = "RS0"

  validation {
    condition     = contains(["RS0", "Standard"], var.sku)
    error_message = "sku must be RS0 or Standard."
  }
}

variable "enable_telemetry" {
  type        = bool
  description = "Controls whether telemetry is sent to Microsoft. Defaults to true."
  default     = true
}
