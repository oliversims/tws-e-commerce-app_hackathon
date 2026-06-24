data "terraform_remote_state" "bootstrap" {
  backend = "local"

  config = {
    path = "${path.module}/../00_bootstrap/terraform.tfstate"
  }
}
