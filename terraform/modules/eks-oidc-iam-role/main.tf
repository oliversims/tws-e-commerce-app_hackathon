# modules/eks-oidc-iam-role — main.tf
# Reusable module: creates an IAM role assumable by a Kubernetes service account (IRSA).
# Called by stacks that need AWS API access from pods (EBS CSI, ALB controller).

# IAM role with a trust policy tied to the EKS OIDC provider (IRSA).
module "this" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.39"

  create_role = true

  role_name      = var.role_name
  provider_url   = var.oidc_provider_url
  role_policy_arns = var.policy_arns

  tags = var.tags
}
