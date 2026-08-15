# 14_external-secrets — data.tf
# Upstream remote state: EKS (04) for OIDC used by IRSA.

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "04_eks/terraform.tfstate"
    region = local.backend_region
  }
}
