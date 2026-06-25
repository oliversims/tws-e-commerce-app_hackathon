# 08_external-dns — data.tf

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "04_eks/terraform.tfstate"
    region = local.backend_region
  }
}

data "terraform_remote_state" "route53_acm" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "02_route53_acm/terraform.tfstate"
    region = local.backend_region
  }
}
