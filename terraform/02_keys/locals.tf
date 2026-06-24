# 02_keys — locals.tf

locals {
  region = data.terraform_remote_state.bootstrap.outputs.state_bucket_region
}
