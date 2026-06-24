# 04_jenkins — variables.tf

# EC2 instance size for the Jenkins server (default: t3.medium).
variable "instance_type" {
  description = "Instance type for the Jenkins server"
  type        = string
  default     = "t3.medium"
}
