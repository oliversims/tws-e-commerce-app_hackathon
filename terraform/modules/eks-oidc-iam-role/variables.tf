# modules/eks-oidc-iam-role — variables.tf
# Input variables: role name, OIDC provider URL, and policy ARNs to attach.

# Name of the IAM role created in AWS (e.g. AmazonEKS_EBS_CSI_DriverRole).
variable "role_name" {
  description = "IAM role name for the Kubernetes service account"
  type        = string
}

# EKS OIDC issuer host without https:// — from stack 04_eks output.
variable "oidc_provider_url" {
  description = "EKS OIDC provider URL without the https:// prefix"
  type        = string
}

# AWS managed or custom policy ARNs attached to the role.
variable "policy_arns" {
  description = "IAM policy ARNs attached to the role"
  type        = list(string)
}

# Optional tags applied to the IAM role resource.
variable "tags" {
  description = "Tags applied to the IAM role"
  type        = map(string)
  default     = {}
}
