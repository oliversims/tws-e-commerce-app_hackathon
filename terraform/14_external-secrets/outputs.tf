output "iam_role_arn" {
  description = "IRSA role ARN annotated on the external-secrets ServiceAccount"
  value       = module.iam_role.iam_role_arn
}
