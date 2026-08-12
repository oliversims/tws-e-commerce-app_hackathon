# 10_ebs-csi-driver — data.tf
# Upstream remote state: EKS (04) for the OIDC provider URL used by IRSA.
# main.tf passes that URL into modules/eks-oidc-iam-role.

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "04_eks/terraform.tfstate"
    region = local.backend_region
  }
}
