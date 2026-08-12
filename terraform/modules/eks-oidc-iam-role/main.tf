# modules/eks-oidc-iam-role — main.tf
# Reusable module: IAM role assumable by a Kubernetes service account (IRSA).
# Used by bastion stacks that need AWS API access from pods (07 ALB, 08 ExternalDNS, 10 EBS CSI).

module "this" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.39"

  create_role = true

  role_name        = var.role_name
  provider_url     = var.oidc_provider_url
  role_policy_arns = var.policy_arns

  tags = var.tags
}
