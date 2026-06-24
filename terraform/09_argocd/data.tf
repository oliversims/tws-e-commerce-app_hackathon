# 09_argocd — data.tf

data "terraform_remote_state" "storage_class" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "07_storage-class/terraform.tfstate"
    region = local.backend_region
  }
}
