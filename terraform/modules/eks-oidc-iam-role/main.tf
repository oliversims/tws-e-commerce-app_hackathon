# IRSA role: a Kubernetes service account assumes this IAM role via EKS OIDC.
# Used by 07 ALB, 08 ExternalDNS, 10 EBS CSI, 14 External Secrets.

module "this" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.39"

  create_role      = true
  role_name        = var.role_name
  provider_url     = var.oidc_provider_url
  role_policy_arns = var.policy_arns
  tags             = var.tags
}
