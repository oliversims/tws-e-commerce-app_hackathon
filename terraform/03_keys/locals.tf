# 03_keys — locals.tf
# Region local: from 00_state (via state.tf) for the AWS provider.
# Apply from your PC after 00_state.

locals {
  region = data.terraform_remote_state.state.outputs.state_bucket_region
}
