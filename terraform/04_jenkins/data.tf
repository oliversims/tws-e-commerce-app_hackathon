# 04_jenkins — data.tf

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "01_vpc/terraform.tfstate"
    region = local.backend_region
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "02_keys/terraform.tfstate"
    region = local.backend_region
  }
}

data "aws_ami" "os_image" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/*24.04-amd64*"]
  }
}
