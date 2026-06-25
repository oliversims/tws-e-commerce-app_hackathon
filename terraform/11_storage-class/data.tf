# 12_storage-class — data.tf

data "terraform_remote_state" "ebs_csi_driver" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "11_ebs-csi-driver/terraform.tfstate"
    region = local.backend_region
  }
}
