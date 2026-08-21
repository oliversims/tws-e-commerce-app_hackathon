# 05_jenkins — variables.tf
# Apply from your PC after 01_vpc and 03_keys.

variable "instance_type" {
  description = "Instance type for the Jenkins server"
  type        = string
  default     = "t3.medium"
}

# Same CIDR as 06_bastion. Update both if your home/office IP changes.
variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH and reach the Jenkins UI (use your public IP /32)"
  type        = string
  default     = "68.195.155.202/32"
}
