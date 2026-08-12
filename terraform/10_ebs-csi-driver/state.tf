# 10_ebs-csi-driver — state.tf
# Reads local 00_state for the S3 backend bucket name and region.
# Shared by every bastion stack so remote-state lookups use one bucket.
# Apply on the bastion after 06_bastion (needs kubectl/kubeconfig).

data "terraform_remote_state" "state" {
  backend = "local"

  config = {
    path = "${path.module}/../00_state/terraform.tfstate"
  }
}
