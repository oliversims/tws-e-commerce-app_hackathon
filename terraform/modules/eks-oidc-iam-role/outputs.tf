# modules/eks-oidc-iam-role — outputs.tf
# Returns the IAM role ARN for annotation on Kubernetes service accounts.

# Role ARN used in the eks.amazonaws.com/role-arn service account annotation.
output "iam_role_arn" {
  description = "ARN of the assumable IAM role"
  value       = module.this.iam_role_arn
}
