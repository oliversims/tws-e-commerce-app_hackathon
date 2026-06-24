# 04_jenkins — locals.tf

locals {
  backend_bucket = data.terraform_remote_state.bootstrap.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.bootstrap.outputs.state_bucket_region
  region         = local.backend_region
}
