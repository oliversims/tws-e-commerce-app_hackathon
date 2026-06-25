# 12_storage-class — locals.tf

locals {
  backend_bucket = data.terraform_remote_state.state.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.state.outputs.state_bucket_region
}
