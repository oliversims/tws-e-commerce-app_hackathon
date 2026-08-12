# 11_storage-class — data.tf
# Upstream remote state: EBS CSI driver (10_ebs-csi-driver) used as an apply-order gate.

data "terraform_remote_state" "ebs_csi_driver" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "10_ebs-csi-driver/terraform.tfstate"
    region = local.backend_region
  }
}
