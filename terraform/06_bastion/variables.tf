# 06_bastion - variables.tf
# Apply from your PC after 04_eks.

variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.medium"
}

# Your public IP as CIDR (x.x.x.x/32). Update if your home/office IP changes.
variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion (use your public IP /32)"
  type        = string
  default     = "68.195.155.202/32"
}
