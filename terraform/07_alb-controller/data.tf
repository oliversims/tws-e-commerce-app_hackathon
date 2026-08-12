# 07_alb-controller — data.tf
# Upstream remote state: VPC (01) and EKS (04) for VPC ID, region, and OIDC/cluster name.
# main.tf uses these when wiring ALB controller Helm values and the IRSA role.

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "01_vpc/terraform.tfstate"
    region = local.backend_region
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "04_eks/terraform.tfstate"
    region = local.backend_region
  }
}
