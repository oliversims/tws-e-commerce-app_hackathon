# 05_bastion — providers.tf

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
    }
  }

  backend "s3" {
    bucket       = "tfstate-tws-us-east-1-681j1a"
    key          = "05_bastion/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = local.region
}
