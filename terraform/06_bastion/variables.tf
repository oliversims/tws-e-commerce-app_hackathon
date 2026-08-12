# 06_bastion — variables.tf
# Inputs for the Bastion EC2 instance size.
# Apply from your PC; default is t3.medium.

variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.medium"
}
