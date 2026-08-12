# 01_vpc — state.tf
# Reads local 00_state/terraform.tfstate for the bucket region (AWS provider).
# Apply from your PC after 00_state so that local state file exists.

data "terraform_remote_state" "state" {
  backend = "local"

  config = {
    path = "${path.module}/../00_state/terraform.tfstate"
  }
}
