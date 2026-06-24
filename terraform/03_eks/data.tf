# 03_eks — data.tf
# Reads outputs from 01_vpc and 02_keys

# Whoever runs terraform apply — used for EKS cluster-admin access.
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "01_vpc/terraform.tfstate"
    region = local.backend_region
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "02_keys/terraform.tfstate"
    region = local.backend_region
  }
}
