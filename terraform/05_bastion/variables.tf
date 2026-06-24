# 05_bastion — variables.tf
# Input variables for the Bastion EC2 instance (instance type).

# EC2 instance size for the Bastion host (default: t3.medium).
variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.medium"
}
