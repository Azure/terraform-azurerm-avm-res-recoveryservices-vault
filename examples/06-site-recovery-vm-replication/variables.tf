variable "source_vms" {
  type = map(object({
    data_disks = map(object({
      lun     = number
      size_gb = number
    }))
  }))
  description = "Map of source VMs and their data disks for Site Recovery replication."

  default = {
    vm1 = {
      data_disks = {
        data1 = {
          lun     = 0
          size_gb = 32
        }
        data2 = {
          lun     = 1
          size_gb = 64
        }
      }
    }
    vm2 = {
      data_disks = {
        data1 = {
          lun     = 0
          size_gb = 32
        }
        data2 = {
          lun     = 1
          size_gb = 128
        }
      }
    }
  }

  validation {
    condition     = length(var.source_vms) > 0
    error_message = "source_vms must include at least one VM."
  }

  validation {
    condition     = alltrue([for _, vm in var.source_vms : length(vm.data_disks) > 0])
    error_message = "Each VM in source_vms must define at least one data disk."
  }

  validation {
    condition = alltrue([
      for _, vm in var.source_vms :
      length(vm.data_disks) == length(toset([for _, disk in vm.data_disks : disk.lun]))
    ])
    error_message = "Each VM in source_vms must use unique LUN values across its data disks."
  }
}

variable "source_vm_size" {
  type        = string
  description = "VM SKU for source VMs used in the Site Recovery example."
  default     = "Standard_D2as_v5"
}

variable "target_vm_size" {
  type        = string
  description = "VM SKU used for failover target replicated VMs. Must be compatible with the source VM's disk controller type (SCSI) and generation; incompatible sizes cause Azure Site Recovery error 1400148. Defaults to the source VM size to guarantee compatibility."
  default     = "Standard_D2as_v5"
}

variable "site_recovery_replication_timeouts" {
  type = object({
    create = string
    update = string
    delete = string
    read   = string
  })
  description = "Timeouts for replicated VM Site Recovery operations. Increase these when Azure replication operations are slow to report completion."
  default = {
    create = "180m"
    update = "180m"
    delete = "120m"
    read   = "15m"
  }
}
