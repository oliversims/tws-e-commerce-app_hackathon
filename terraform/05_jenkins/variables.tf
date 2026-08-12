# 05_jenkins — variables.tf
# Apply from your PC after 01_vpc and 03_keys.

variable "instance_type" {
  description = "Instance type for the Jenkins server"
  type        = string
  default     = "t3.medium"
}
