variable "bypass_ip_cidr" {
  type        = string
  default     = null
  description = "value to bypass the IP CIDR on firewall rules"
}
variable "subscription_id" {
  description = "The Azure subscription ID where the resources will be created."
  type        = string
  default     = ""
}

