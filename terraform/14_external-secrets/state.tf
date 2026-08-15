# 14_external-secrets — state.tf
# Reads local 00_state for the S3 backend bucket name and region.

data "terraform_remote_state" "state" {
  backend = "local"

  config = {
    path = "${path.module}/../00_state/terraform.tfstate"
  }
}
