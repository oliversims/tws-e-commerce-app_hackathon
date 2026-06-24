# 06_ebs-csi-driver — data.tf

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "03_eks/terraform.tfstate"
    region = local.backend_region
  }
}
