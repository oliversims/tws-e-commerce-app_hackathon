# 05_jenkins — variables.tf
# Apply from your PC after 01_vpc and 03_keys.

variable "instance_type" {
  description = "Instance type for the Jenkins server"
  type        = string
  default     = "t3.medium"
}

# Empty = new Ubuntu + install script. Set by snapshot-and-destroy.sh after you save an AMI.
variable "jenkins_ami_id" {
  description = "Jenkins AMI ID (leave empty for first install)"
  type        = string
  default     = ""
}
