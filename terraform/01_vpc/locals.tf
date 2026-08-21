# 01_vpc — locals.tf
# Region from 00_state; network layout for VPC / EKS naming.
# Apply from your PC after 00_state.

locals {
  region = data.terraform_remote_state.state.outputs.state_bucket_region

  # VPC layout — name is also the EKS cluster name consumed by 04_eks / 06_bastion.
  name     = "tws-eks-cluster"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["${local.region}a", "${local.region}b", "${local.region}c"]

  # One public + one private /24 per AZ (a, b, c).
  # Public:  ALB, NAT, Jenkins, bastion
  # Private: EKS managed nodes + Karpenter nodes
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.5.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24", "10.0.6.0/24"]
}
