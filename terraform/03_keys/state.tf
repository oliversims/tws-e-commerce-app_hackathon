# 03_keys — state.tf
# Reads local 00_state/terraform.tfstate for the S3 bucket name + region.
# Those values feed locals (region) used by the AWS provider for this stack.
# Apply from your PC after 00_state so that local state file exists.

data "terraform_remote_state" "state" {
  backend = "local"

  config = {
    path = "${path.module}/../00_state/terraform.tfstate"
  }
}
