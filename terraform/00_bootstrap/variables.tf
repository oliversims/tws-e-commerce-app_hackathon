variable "environment_name" {
  description = "Environment name used in the state bucket name"
  type        = string
  default     = "tws"
}

variable "aws_region" {
  description = "AWS region where the state bucket is created"
  type        = string
  default     = "us-east-1"
}
