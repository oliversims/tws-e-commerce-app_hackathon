# 04_eks — state.tf
# Reads local 00_state/terraform.tfstate for the S3 bucket name + region.
# Those values feed locals used by this stack's S3 backend / remote_state data sources.
# Apply from your PC after 00_state so that local state file exists.

data "terraform_remote_state" "state" {
  backend = "local"

  config = {
    path = "${path.module}/../00_state/terraform.tfstate"
  }
}
