# 06_bastion — data.tf
# Upstream remote state + AMI/account lookups for the bastion host.
# Reads 01_vpc (placement), 03_keys (SSH), and 04_eks (cluster access / kubeconfig).
# Apply from your PC after those stacks.

# VPC ID and public subnet for the bastion EC2.
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "01_vpc/terraform.tfstate"
    region = local.backend_region
  }
}

# Deployer key pair name for SSH into the bastion.
data "terraform_remote_state" "keys" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "03_keys/terraform.tfstate"
    region = local.backend_region
  }
}

# EKS cluster name for access entries and user_data kubeconfig setup.
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = local.backend_bucket
    key    = "04_eks/terraform.tfstate"
    region = local.backend_region
  }
}

data "aws_caller_identity" "current" {}

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
