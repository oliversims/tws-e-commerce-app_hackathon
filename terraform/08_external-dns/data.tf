# 08_external-dns — data.tf
# Upstream remote state: EKS (04) for OIDC/cluster name; Route53/ACM (02) for hosted zone.
# main.tf uses these for the IRSA policy scope and Helm values (zone ID, txt owner).

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
