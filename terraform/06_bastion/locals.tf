# 06_bastion — locals.tf
# Backend locals: bucket/region from 00_state (via state.tf) for remote_state + S3 upload.
# state_key: S3 object path for the uploaded 00_state copy (see state_upload.tf).
# Apply from your PC after 00_state.

locals {
  backend_bucket = data.terraform_remote_state.state.outputs.state_bucket_name
  backend_region = data.terraform_remote_state.state.outputs.state_bucket_region
  region         = local.backend_region

  state_key = "bastion/state.tfstate"
}
