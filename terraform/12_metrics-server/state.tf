data "terraform_remote_state" "state" {
  backend = "local"

  config = {
    path = "${path.module}/../00_state/terraform.tfstate"
  }
}
