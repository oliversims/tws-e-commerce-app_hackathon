# 04_eks — data.tf
# Upstream remote state + IAM identity used while creating the cluster.
# Reads 01_vpc (network placement) and 03_keys (node SSH key).
# Apply from your PC after those stacks.

# Whoever runs terraform apply — used for EKS cluster-admin access.
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# VPC ID, private subnets, and cluster name from 01_vpc.
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "01_vpc/terraform.tfstate"
    region = local.backend_region
  }
}

# Deployer key pair name from 03_keys (node group remote_access).
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "03_keys/terraform.tfstate"
    region = local.backend_region
  }
}
