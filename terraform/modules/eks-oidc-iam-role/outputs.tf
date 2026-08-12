# modules/eks-oidc-iam-role — outputs.tf
# Returns the IAM role ARN for the calling stack.
# Callers annotate the service account with eks.amazonaws.com/role-arn.

output "iam_role_arn" {
  description = "ARN of the assumable IAM role"
  value       = module.this.iam_role_arn
}
