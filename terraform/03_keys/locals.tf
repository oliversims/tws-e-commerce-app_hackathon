# 03_keys — locals.tf

locals {
  region = data.terraform_remote_state.state.outputs.state_bucket_region
}
