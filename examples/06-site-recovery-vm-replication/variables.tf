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
  default     = "Standard_D2s_v3"
}
