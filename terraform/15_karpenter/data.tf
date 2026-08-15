# 15_karpenter — data.tf
# Upstream remote state: EKS (04) for cluster name, interruption queue, and node IAM role.

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "04_eks/terraform.tfstate"
    region = local.backend_region
  }
}
