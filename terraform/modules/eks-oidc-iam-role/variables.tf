variable "role_name" {
  description = "IAM role name for the Kubernetes service account"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL without the https:// prefix"
  type        = string
}

variable "policy_arns" {
  description = "IAM policy ARNs attached to the role"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to the IAM role"
  type        = map(string)
  default     = {}
}
