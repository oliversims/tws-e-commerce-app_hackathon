# 07_alb-controller — data.tf

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
