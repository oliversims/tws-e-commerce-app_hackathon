# 05_jenkins — data.tf
# Upstream remote state + AMI lookup for the Jenkins EC2.
# Reads 01_vpc (placement) and 03_keys (SSH key); Ubuntu 24.04 AMI from Canonical.
# Apply from your PC after those stacks.

# VPC ID and public subnet for the Jenkins instance.
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "01_vpc/terraform.tfstate"
    region = local.backend_region
  }
}

# Deployer key pair name for SSH into Jenkins.
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "03_keys/terraform.tfstate"
    region = local.backend_region
  }
}

# Latest Ubuntu 24.04 amd64 AMI (Canonical).
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
