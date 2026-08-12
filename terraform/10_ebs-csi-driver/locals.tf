# 10_ebs-csi-driver — locals.tf
# Backend locals from 00_state — used by data.tf remote-state lookups and the AWS provider.

locals {
  backend_bucket = data.terraform_remote_state.state.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.state.outputs.state_bucket_region
  region         = local.backend_region
}
