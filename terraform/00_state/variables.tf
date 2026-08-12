# 00_state — variables.tf
# Inputs for naming the state bucket and choosing its AWS region.
# Apply from your PC; defaults match the rest of this project's us-east-1 layout.

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
